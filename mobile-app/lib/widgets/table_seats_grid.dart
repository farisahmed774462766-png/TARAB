import 'package:flutter/material.dart';
import '../models/table_model.dart';

class TableSeatsGrid extends StatelessWidget {
  final TarabTable table;
  final bool isArabic;

  const TableSeatsGrid({
    super.key,
    required this.table,
    this.isArabic = true,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = table.canStartLegalGame
        ? (isArabic
            ? 'المقاعد مكتملة (5/5) — جاهز لبدء اللعبة القانونية'
            : 'Seats full (5/5) — Ready for legal start')
        : (isArabic
            ? 'بانتظار اكتمال المقاعد (${table.occupiedSeatsCount}/${TarabTable.totalSeats})'
            : 'Waiting for seats (${table.occupiedSeatsCount}/${TarabTable.totalSeats})');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic
                      ? 'رسوم الدخول: ${table.entryFee} كوينز'
                      : 'Entry fee: ${table.entryFee} coins',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: table.seats.map((seat) => _buildSeatCard(context, seat)).toList(),
        ),
      ],
    );
  }

  Widget _buildSeatCard(BuildContext context, TableSeat seat) {
    final String label;
    final String subtitle;

    if (!seat.isOccupied) {
      label = isArabic ? 'مقعد ${seat.seatNumber}' : 'Seat ${seat.seatNumber}';
      subtitle = isArabic ? 'متاح' : 'Available';
    } else if (seat.isBot) {
      label = seat.playerName ?? (isArabic ? 'شخصية آلية' : 'Bot');
      subtitle = isArabic ? 'لاعب آلي • مقعد ${seat.seatNumber}' : 'Bot • Seat ${seat.seatNumber}';
    } else {
      label = seat.playerName ?? (isArabic ? 'لاعب' : 'Player');
      final conn = seat.isConnected
          ? (isArabic ? 'متصل' : 'Online')
          : (isArabic ? 'غير متصل' : 'Offline');
      subtitle = '$conn • ${isArabic ? 'مقعد' : 'Seat'} ${seat.seatNumber}';
    }

    return SizedBox(
      width: 165,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
