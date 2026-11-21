const { seatPlayer, removePlayerFromSeat, canStartLegalGame } = require("./table_manager");
const { canEnterTable } = require("./economy_manager");

function joinTableWithWallet({ table, wallet, playerName, isBot = false, isConnected = true }) {
  if (!isBot) {
    const entryCheck = canEnterTable(wallet, table.entryFee);
    if (!entryCheck.allowed) {
      return {
        joined: false,
        reason: entryCheck.reason,
        details: entryCheck,
        table,
        wallet,
      };
    }

    wallet.coins -= table.entryFee;
    wallet.transactions.push({
      type: "TABLE_ENTRY_FEE",
      tableId: table.tableId,
      amount: table.entryFee,
      currentCoins: wallet.coins,
      remainingDebt: wallet.debt,
      timestamp: new Date().toISOString(),
    });
  }

  try {
    const seatResult = seatPlayer(table, {
      playerId: wallet.playerId,
      playerName,
      isBot,
      isConnected,
    });

    return {
      joined: true,
      assignedSeat: seatResult.assignedSeat,
      canStartLegalGame: seatResult.canStartLegalGame,
      table: seatResult.table,
      wallet,
    };
  } catch (err) {
    // إعادة رسوم الدخول في حال تعذر تسكين اللاعب
    if (!isBot) {
      wallet.coins += table.entryFee;
      wallet.transactions.pop();
    }

    return {
      joined: false,
      reason: err.message,
      table,
      wallet,
    };
  }
}

function leaveTable({ table, playerId }) {
  const result = removePlayerFromSeat(table, playerId);
  return {
    table: result.table,
    removed: result.removed,
    canStartLegalGame: result.canStartLegalGame || canStartLegalGame(result.table),
  };
}

module.exports = {
  joinTableWithWallet,
  leaveTable,
};
