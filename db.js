const { Pool } = require("pg");
const { createPlayerWallet } = require("./economy_manager");

let pool = null;

function getPool() {
  if (!pool && process.env.DATABASE_URL) {
    pool = new Pool({
      connectionString: process.env.DATABASE_URL,
    });
  }
  return pool;
}

async function ensurePlayerAndWallet(playerId, displayName = null, initialCoins = 10000) {
  const db = getPool();
  if (!db) {
    return createPlayerWallet({ playerId, coins: initialCoins, debt: 0 });
  }

  await db.query(
    `INSERT INTO players (player_id, display_name)
     VALUES ($1, $2)
     ON CONFLICT (player_id) DO UPDATE SET display_name = COALESCE(EXCLUDED.display_name, players.display_name)`,
    [playerId, displayName || `لاعب ${playerId}`]
  );

  await db.query(
    `INSERT INTO player_wallets (player_id, coins, debt)
     VALUES ($1, $2, 0)
     ON CONFLICT (player_id) DO NOTHING`,
    [playerId, initialCoins]
  );

  const res = await db.query(
    `SELECT player_id, coins, debt FROM player_wallets WHERE player_id = $1`,
    [playerId]
  );
  const row = res.rows[0] || { player_id: playerId, coins: initialCoins, debt: 0 };

  return createPlayerWallet({
    playerId: row.player_id,
    coins: Number(row.coins) || 0,
    debt: Number(row.debt) || 0,
  });
}

async function saveWalletAndTransaction(wallet, lastTx = null) {
  const db = getPool();
  if (!db) return;

  await db.query(
    `UPDATE player_wallets SET coins = $2, debt = $3, updated_at = NOW() WHERE player_id = $1`,
    [wallet.playerId, wallet.coins, wallet.debt]
  );

  if (lastTx) {
    await db.query(
      `INSERT INTO wallet_transactions
       (player_id, tx_type, source, amount, paid_towards_debt, added_coins, remaining_debt)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        wallet.playerId,
        lastTx.type || "REWARD",
        lastTx.source || "system",
        lastTx.amount || 0,
        lastTx.paidTowardsDebt || 0,
        lastTx.addedCoins || 0,
        lastTx.remainingDebt ?? wallet.debt,
      ]
    );
  }
}

async function saveTableState(table) {
  const db = getPool();
  if (!db) return;

  await db.query(
    `INSERT INTO game_tables (table_id, is_private, entry_fee)
     VALUES ($1, $2, $3)
     ON CONFLICT (table_id) DO UPDATE SET is_private = EXCLUDED.is_private, entry_fee = EXCLUDED.entry_fee`,
    [table.tableId, Boolean(table.isPrivate), Number(table.entryFee) || 1000]
  );

  for (const seat of table.seats || []) {
    await db.query(
      `INSERT INTO table_seats (table_id, seat_number, player_id, player_name, is_bot, is_connected)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (table_id, seat_number) DO UPDATE SET
         player_id = EXCLUDED.player_id,
         player_name = EXCLUDED.player_name,
         is_bot = EXCLUDED.is_bot,
         is_connected = EXCLUDED.is_connected`,
      [
        table.tableId,
        seat.seatNumber,
        seat.playerId || null,
        seat.playerName || null,
        Boolean(seat.isBot),
        Boolean(seat.isConnected),
      ]
    );
  }
}

module.exports = {
  getPool,
  ensurePlayerAndWallet,
  saveWalletAndTransaction,
  saveTableState,
};
