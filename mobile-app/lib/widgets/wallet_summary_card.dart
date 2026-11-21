import 'package:flutter/material.dart';
import '../models/wallet_model.dart';

class WalletSummaryCard extends StatelessWidget {
  final PlayerWallet wallet;
  final int entryFee;
  final bool isArabic;

  const WalletSummaryCard({
    super.key,
    required this.wallet,
    required this.entryFee,
    this.isArabic = true,
  });

  @override
  Widget build(BuildContext context) {
    final canEnter = wallet.canEnterTable(entryFee);
    final blockReason = wallet.entryBlockReason(entryFee, isArabic: isArabic);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'محفظة اللاعب (${wallet.playerId})' : 'Player Wallet (${wallet.playerId})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  canEnter
                      ? (isArabic ? 'مسموح بالدخول' : 'Entry Allowed')
                      : (isArabic ? 'دخول الطاولة متوقف' : 'Table Entry Blocked'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: canEnter ? Colors.teal : Colors.red,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'رصيد الكوينز: ${wallet.coins}' : 'Coins: ${wallet.coins}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  isArabic ? 'قيمة الدين: ${wallet.debt}' : 'Debt: ${wallet.debt}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: wallet.hasDebt ? Colors.red : Colors.green,
                      ),
                ),
              ],
            ),
            if (!canEnter && blockReason.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                blockReason,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red.shade700,
                    ),
              ),
            ],
            if (wallet.hasDebt) ...[
              const SizedBox(height: 6),
              Text(
                isArabic
                    ? 'ملاحظة: يتم تخصيص المكافآت والإعلانات الاختيارية تلقائياً لسداد الدين أولاً.'
                    : 'Note: Rewards and optional ads are automatically applied to debt first.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
