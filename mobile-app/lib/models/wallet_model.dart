class WalletTransaction {
  final String type;
  final String? source;
  final int amount;
  final int paidTowardsDebt;
  final int addedCoins;
  final int remainingDebt;
  final DateTime timestamp;

  const WalletTransaction({
    required this.type,
    this.source,
    required this.amount,
    this.paidTowardsDebt = 0,
    this.addedCoins = 0,
    required this.remainingDebt,
    required this.timestamp,
  });
}

class PlayerWallet {
  final String playerId;
  final int coins;
  final int debt;
  final List<WalletTransaction> transactions;

  const PlayerWallet({
    required this.playerId,
    required this.coins,
    required this.debt,
    this.transactions = const [],
  });

  bool get hasDebt => debt > 0;

  bool canEnterTable(int entryFee) {
    if (hasDebt) return false;
    return coins >= entryFee;
  }

  String entryBlockReason(int entryFee, {bool isArabic = true}) {
    if (hasDebt) {
      return isArabic
          ? 'لا يمكن دخول جولة جديدة حتى يتم سداد الدين ($debt كوينز)'
          : 'Cannot enter a new round until debt ($debt coins) is settled';
    }
    if (coins < entryFee) {
      return isArabic
          ? 'رصيد الكوينز غير كافٍ لدفع رسوم الدخول ($entryFee كوينز)'
          : 'Insufficient coins for entry fee ($entryFee coins)';
    }
    return '';
  }
}
