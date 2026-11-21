const http = require("http");
const { WebSocketServer } = require("ws");

const PORT = process.env.PORT || 3000;
const SEATS_PER_TABLE = 5;

const server = http.createServer((req, res) => {
  if (req.url === "/health") {
    res.writeHead(200, { "Content-Type": "application/json; charset=utf-8" });
    res.end(
      JSON.stringify({
        service: "TARAB Game Server",
        status: "running",
        seatsPerTable: SEATS_PER_TABLE,
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
      seatsPerTable: SEATS_PER_TABLE,
    })
  );

  socket.on("message", (rawData) => {
    try {
      const event = JSON.parse(rawData.toString());
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
          message: "صيغة الرسالة غير صالحة (JSON مطلوب)",
        })
      );
    }
  });
});

server.listen(PORT, () => {
  console.log(`TARAB server listening on port ${PORT}`);
});
