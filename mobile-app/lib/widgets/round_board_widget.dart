import 'package:flutter/material.dart';

class RoundBoardWidget extends StatelessWidget {
  final Map<String, dynamic>? round;
  final String currentPlayerId;
  final bool isArabic;
  final VoidCallback onStartRound;
  final void Function(String cardId) onPlayCard;

  const RoundBoardWidget({
    super.key,
    required this.round,
    required this.currentPlayerId,
    required this.isArabic,
    required this.onStartRound,
    required this.onPlayCard,
  });

  @override
  Widget build(BuildContext context) {
    final activeRound = round;
    final status = activeRound?['status'] as String? ?? 'IDLE';
    final turnPlayerId = activeRound?['currentTurnPlayerId'] as String?;
    final winnerId = activeRound?['winnerId'] as String?;

    final handsMap = activeRound?['hands'] is Map<String, dynamic>
        ? activeRound!['hands'] as Map<String, dynamic>
        : <String, dynamic>{};
    final myHand = handsMap[currentPlayerId] is List<dynamic>
        ? (handsMap[currentPlayerId] as List<dynamic>)
            .whereType>()
            .toList()
        : >[];

    final playedCards = activeRound?['tableCards'] is List<dynamic>
        ? (activeRound!['tableCards'] as List<dynamic>)
            .whereType>()
            .toList()
        : >[];

    final isMyTurn = status == 'IN_PROGRESS' && turnPlayerId == currentPlayerId;

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
                  isArabic ? 'جولة الأوراق واللعب' : 'Card Round',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ElevatedButton(
                  onPressed: onStartRound,
                  child: Text(isArabic ? 'بدء جولة' : 'Start Round'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isArabic
                  ? 'حالة الجولة: $status • الدور الحالي: ${turnPlayerId ?? "-"}'
                  : 'Status: $status • Turn: ${turnPlayerId ?? "-"}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (winnerId != null) ...[
              const SizedBox(height: 6),
              Text(
                isArabic ? 'فائز الجولة: $winnerId' : 'Round Winner: $winnerId',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              isArabic
                  ? 'الأوراق على الطاولة (${playedCards.length})'
                  : 'Table Cards (${playedCards.length})',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: playedCards.map((item) {
                final card = item['card'] as Map<String, dynamic>? ?? {};
                final pid = item['playerId'] as String? ?? '';
                final label = '${card['rank'] ?? ''} ${card['suit'] ?? ''} ($pid)';
                return Chip(label: Text(label));
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              isArabic
                  ? 'أوراقك الحالية (${myHand.length}) ${isMyTurn ? "• دورك الآن" : ""}'
                  : 'Your Hand (${myHand.length}) ${isMyTurn ? "• Your Turn" : ""}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isMyTurn ? Colors.teal : null,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: myHand.map((card) {
                final cardId = card['id'] as String? ?? '';
                final label = '${card['rank'] ?? ''} • ${card['suit'] ?? ''}';
                return OutlinedButton(
                  onPressed: isMyTurn && cardId.isNotEmpty
                      ? () => onPlayCard(cardId)
                      : null,
                  child: Text(label),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
