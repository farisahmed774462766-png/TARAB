١const http = require("http");
const { WebSocketServer } = require("ws");
const {
  TOTAL_SEATS,
  MIN_ENTRY_FEE,
  MAX_ENTRY_FEE,
  createTable,
  canStartLegalGame,
} = require("./table_manager");
const {
  createPlayerWallet,
  applyReward,
  settleDebtManually,
} = require("./economy_manager");
const { joinTableWithWallet, leaveTable } = require("./game_session");

const PORT = process.env.PORT || 3000;

const tables = new Map();
const wallets = new Map();

function getOrCreateWallet(playerId) {
  if (!wallets.has(playerId)) {
    wallets.set(playerId, createPlayerWallet({ playerId, coins: 10000, debt: 0 }));
  }
  return wallets.get(playerId);
}

const server = http.createServer((req, res) => {
  if (req.url === "/health") {
    res.writeHead(200, { "Content-Type": "application/json; charset=utf-8" });
    res.end(
      JSON.stringify({
        service: "TARAB Game Server",
        status: "running",
        seatsPerTable: TOTAL_SEATS,
        entryFeeRange: { min: MIN_ENTRY_FEE, max: MAX_ENTRY_FEE },
        activeTables: tables.size,
      })
    );
    return;
  }

  res.writeHead(200, { "Content-Type": "text/plain; charset=utf-8" });
  res.end("TARAB WebSocket & Game Server is active");
});

const wss = new WebSocketServer({ server });

wss.on("connection", (socket) => {
  socket.send(
    JSON.stringify({
      type: "WELCOME",
      message: "مرحباً بك في خادم لعبة طراب (TARAB)",
      seatsPerTable: TOTAL_SEATS,
    })
  );

  socket.on("message", (rawData) => {
    try {
      const event = JSON.parse(rawData.toString());
      const payload = event.payload || {};

      if (event.type === "CREATE_TABLE") {
        const tableId = payload.tableId || `TBL-${tables.size + 1}`;
        const table = createTable({
          tableId,
          isPrivate: Boolean(payload.isPrivate),
          entryFee: Number(payload.entryFee ?? MIN_ENTRY_FEE),
        });
        tables.set(tableId, table);
        socket.send(JSON.stringify({ type: "TABLE_CREATED", table }));
        return;
      }

      if (event.type === "JOIN_TABLE") {
        const table = tables.get(payload.tableId);
        if (!table) {
          socket.send(JSON.stringify({ type: "ERROR", message: "الطاولة غير موجودة" }));
          return;
        }
        const wallet = getOrCreateWallet(payload.playerId);
        const result = joinTableWithWallet({
          table,
          wallet,
          playerName: payload.playerName,
          isBot: Boolean(payload.isBot),
          isConnected: true,
        });
        socket.send(JSON.stringify({ type: "JOIN_RESULT", ...result }));
        return;
      }

      if (event.type === "LEAVE_TABLE") {
        const table = tables.get(payload.tableId);
        if (!table) {
          socket.send(JSON.stringify({ type: "ERROR", message: "الطاولة غير موجودة" }));
          return;
        }
        const result = leaveTable({ table, playerId: payload.playerId });
        socket.send(JSON.stringify({ type: "LEAVE_RESULT", ...result }));
        return;
      }

      if (event.type === "APPLY_REWARD") {
        const wallet = getOrCreateWallet(payload.playerId);
        applyReward(wallet, payload.amount, payload.source || "daily_reward");
        socket.send(JSON.stringify({ type: "WALLET_UPDATED", wallet }));
        return;
      }

      if (event.type === "SETTLE_DEBT") {
        const wallet = getOrCreateWallet(payload.playerId);
        const settlement = settleDebtManually(wallet, payload.amount);
        socket.send(JSON.stringify({ type: "DEBT_SETTLED", settlement, wallet }));
        return;
      }

      socket.send(
        JSON.stringify({
          type: "ACK",
          receivedType: event.type || "UNKNOWN",
          timestamp: new Date().toISOString(),
        })
      );
    } catch (err) {
      socket.send(
        JSON.stringify({
          type: "ERROR",
          message: err.message || "صيغة الرسالة غير صالحة (JSON مطلوب)",
        })
      );
    }
  });
});

server.listen(PORT, () => {
  console.log(`TARAB server listening on port ${PORT}`);
});
