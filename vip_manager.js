const GRACE_PERIOD_DAYS = 3;

function createVipAccount({ playerId, tier = "NONE", vipPoints = 0, expiresAt = null }) {
  return {
    playerId,
    tier,
    vipPoints,
    expiresAt,
    history: [],
  };
}

function evaluateSubscriptionStatus(account, now = new Date()) {
  if (!account.expiresAt) {
    return account;
  }
  const expiryTime = new Date(account.expiresAt).getTime();
  const diffDays = (now.getTime() - expiryTime) / (1000 * 60 * 60 * 24);
  if (diffDays > GRACE_PERIOD_DAYS) {
    account.tier = "NONE";
  }
  return account;
}

function awardVipPoints(account, points, reason = "activity") {
  const safePoints = Math.max(0, Number(points) || 0);
  account.vipPoints += safePoints;
  const record = {
    type: "AWARD",
    points: safePoints,
    reason,
    timestamp: new Date().toISOString(),
  };
  account.history.push(record);
  return { account, record };
}

function redeemVipPointsForCoins(account, pointsToRedeem, coinsPerPoint = 10) {
  const amount = Math.max(0, Number(pointsToRedeem) || 0);
  if (amount <= 0 || account.vipPoints < amount) {
    throw new Error("رصيد نقاط VIP غير كافٍ للاستبدال");
  }
  account.vipPoints -= amount;
  const coinsEarned = amount * coinsPerPoint;
  account.history.push({
    type: "REDEEM",
    points: amount,
    coinsEarned,
    timestamp: new Date().toISOString(),
  });
  return { coinsEarned, remainingPoints: account.vipPoints, account };
}

module.exports = {
  GRACE_PERIOD_DAYS,
  createVipAccount,
  evaluateSubscriptionStatus,
  awardVipPoints,
  redeemVipPointsForCoins,
};
