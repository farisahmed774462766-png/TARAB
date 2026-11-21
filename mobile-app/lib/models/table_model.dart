class TableSeat {
  final int seatNumber;
  final String? playerId;
  final String? playerName;
  final bool isBot;
  final bool isConnected;

  const TableSeat({
    required this.seatNumber,
    this.playerId,
    this.playerName,
    this.isBot = false,
    this.isConnected = false,
  });

  bool get isOccupied => playerId != null && playerId!.isNotEmpty;
}

class TarabTable {
  static const int totalSeats = 5;

  final String tableId;
  final bool isPrivate;
  final int entryFee;
  final List<TableSeat> seats;

  const TarabTable({
    required this.tableId,
    required this.isPrivate,
    required this.entryFee,
    required this.seats,
  });

  int get occupiedSeatsCount => seats.where((seat) => seat.isOccupied).length;

  bool get isFull => occupiedSeatsCount == totalSeats;

  bool get canStartLegalGame => isFull;
}
