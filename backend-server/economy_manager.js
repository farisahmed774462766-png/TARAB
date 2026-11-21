function createPlayerWallet({ playerId, coins = 0, debt = 0 }) {
  return {
    playerId,
    coins: Math.max(0, Number(coins) || 0),
    debt: Math.max(0, Number(debt) || 0),
    transactions: [],
  };
}

function canEnterTable(wallet, entryFee) {
  if (wallet.debt > 0) {
    return {
      allowed: false,
      reason: "لا يمكن دخول جولة جديدة حتى يتم سداد الدين بالكامل",
      currentDebt: wallet.debt,
    };
  }

  if (wallet.coins < entryFee) {
    return {
      allowed: false,
      reason: "رصيد الكوينز غير كافٍ لدفع رسوم الدخول",
      requiredCoins: entryFee,
      currentCoins: wallet.coins,
    };
  }

  return { allowed: true };
}

function applyReward(wallet, amount, source = "reward") {
  const rewardAmount = Math.max(0, Number(amount) || 0);
  if (rewardAmount === 0) return wallet;

  let remainingReward = rewardAmount;
  let paidTowardsDebt = 0;

  // تخصيص المكافآت تلقائياً لسداد الدين أولاً
  if (wallet.debt > 0) {
    paidTowardsDebt = Math.min(wallet.debt, remainingReward);
    wallet.debt -= paidTowardsDebt;
    remainingReward -= paidTowardsDebt;
  }

  wallet.coins += remainingReward;

  wallet.transactions.push({
    type: "REWARD",
    source,
    totalAmount: rewardAmount,
    paidTowardsDebt,
    addedCoins: remainingReward,
    remainingDebt: wallet.debt,
    currentCoins: wallet.coins,
    timestamp: new Date().toISOString(),
  });

  return wallet;
}

function settleDebtManually(wallet, amount) {
  const payment = Math.max(0, Number(amount) || 0);
  const actualPayment = Math.min(wallet.debt, wallet.coins, payment);

  wallet.coins -= actualPayment;
  wallet.debt -= actualPayment;

  wallet.transactions.push({
    type: "DEBT_PAYMENT",
    amount: actualPayment,
    remainingDebt: wallet.debt,
    currentCoins: wallet.coins,
    timestamp: new Date().toISOString(),
  });

  return {
    paidAmount: actualPayment,
    remainingDebt: wallet.debt,
    currentCoins: wallet.coins,
  };
}

module.exports = {
  createPlayerWallet,
  canEnterTable,
  applyReward,
  settleDebtManually,
};
