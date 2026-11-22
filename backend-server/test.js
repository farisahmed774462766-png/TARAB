const { describe, it } = require("node:test");
const assert = require("node:assert/strict");

const { TOTAL_SEATS, MIN_ENTRY_FEE, MAX_ENTRY_FEE, createTable } = require("./table_manager");
const { createPlayerWallet, applyReward } = require("./economy_manager");
const { joinTableWithWallet } = require("./game_session");
const { startCardRound, playCard } = require("./card_round_manager");
const { createPlayerRankProfile, resetSeasonPoints } = require("./season_manager");
const { createSocialProfile, sendFriendRequest, acceptFriendRequest, MAX_FRIENDS } = require("./social_manager");
const { createVipAccount, redeemVipPointsForCoins } = require("./vip_manager");

describe("TARAB Core Game & Economy Rules", () => {
  it("creates a 5-seat table within allowed entry fee range", () => {
    const table = createTable({ tableId: "TBL-TEST-1", entryFee: 5000 });
    assert.equal(TOTAL_SEATS, 5);
    assert.equal(MIN_ENTRY_FEE, 1000);
    assert.equal(MAX_ENTRY_FEE, 100000);
    assert.equal(table.seats.length, 5);
    assert.equal(table.entryFee, 5000);
  });

  it("blocks joining when debt exists, then settles debt first on reward", () => {
    const table = createTable({ tableId: "TBL-TEST-2", entryFee: 2000 });
    const wallet = createPlayerWallet({ playerId: "P-1", coins: 5000, debt: 3000 });

    const blockedJoin = joinTableWithWallet({
      table,
      wallet,
      playerName: "لاعب 1",
    });
    assert.equal(blockedJoin.joined, false);

    // صرف مكافأة 5000: تسدد الدين 3000 أولاً وتضيف 2000 إلى الكوينز
    applyReward(wallet, 5000, "daily_reward");
    assert.equal(wallet.debt, 0);
    assert.equal(wallet.coins, 7000);

    const allowedJoin = joinTableWithWallet({
      table,
      wallet,
      playerName: "لاعب 1",
    });
    assert.equal(allowedJoin.joined, true);
  });

  it("deals cards and progresses turns in a full 5-seat round", () => {
    const table = createTable({ tableId: "TBL-TEST-3", entryFee: 1000 });
    for (let i = 1; i <= 5; i++) {
      joinTableWithWallet({
        table,
        playerId: `BOT-${i}`,
        playerName: `بوت ${i}`,
        isBot: true,
      });
    }

    const round = startCardRound(table, 2);
    assert.equal(round.status, "IN_PROGRESS");
    assert.equal(round.turnOrder.length, 5);

    const firstPlayer = round.currentTurnPlayerId;
    const firstCard = round.hands[firstPlayer][0];
    playCard(round, { playerId: firstPlayer, cardId: firstCard.id });

    assert.equal(round.tableCards.length, 1);
    assert.notEqual(round.currentTurnPlayerId, firstPlayer);
  });

  it("supports friend requests, VIP point redemption, and season reset", () => {
    const p1 = createSocialProfile({ playerId: "U1" });
    const p2 = createSocialProfile({ playerId: "U2" });
    sendFriendRequest(p1, p2);
    acceptFriendRequest(p2, p1);
    assert.equal(MAX_FRIENDS, 30);
    assert.ok(p1.friends.includes("U2"));

    const vip = createVipAccount({ playerId: "U1", vipPoints: 50 });
    const redeemed = redeemVipPointsForCoins(vip, 20);
    assert.equal(redeemed.coinsEarned, 200);
    assert.equal(vip.vipPoints, 30);

    const rank = createPlayerRankProfile({ playerId: "U1", displayName: "لاعب", rankPoints: 150 });
    const [resetProfile] = resetSeasonPoints([rank], "Season 1");
    assert.equal(resetProfile.rankPoints, 0);
    assert.equal(resetProfile.historicalAchievements.length, 1);
  });
});
