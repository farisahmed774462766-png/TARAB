import 'dart:async';
import 'package:flutter/material.dart';
import 'models/table_model.dart';
import 'models/wallet_model.dart';
import 'services/tarab_socket_service.dart';
import 'widgets/round_board_widget.dart';
import 'widgets/table_seats_grid.dart';
import 'widgets/wallet_summary_card.dart';

void main() {
  runApp(const TarabApp());
}

class TarabApp extends StatefulWidget {
  const TarabApp({super.key});

  @override
  State<TarabApp> createState() => _TarabAppState();
}

class _TarabAppState extends State<TarabApp> {
  Locale _locale = const Locale('ar');

  void _toggleLanguage() {
    setState(() {
      _locale = _locale.languageCode == 'ar'
          ? const Locale('en')
          : const Locale('ar');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = _locale.languageCode == 'ar';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TARAB',
      locale: _locale,
      builder: (context, child) {
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: TarabHomeScreen(
        isArabic: isArabic,
        onToggleLanguage: _toggleLanguage,
      ),
    );
  }
}

class TarabHomeScreen extends StatefulWidget {
  final bool isArabic;
  final VoidCallback onToggleLanguage;

  const TarabHomeScreen({
    super.key,
    required this.isArabic,
    required this.onToggleLanguage,
  });

  @override
  State<TarabHomeScreen> createState() => _TarabHomeScreenState();
}

class _TarabHomeScreenState extends State<TarabHomeScreen> {
  final TarabSocketService _socketService = TarabSocketService();
  StreamSubscription>? _subscription;

  String _connectionStatus = 'غير متصل بالخادم';
  String? _lastFeedback;
  late TarabTable _table;
  late PlayerWallet _wallet;
  Map<String, dynamic>? _round;

  @override
  void initState() {
    super.initState();
    _table = _initialTable();
    _wallet = _initialWallet();
    _subscription = _socketService.events.listen(_handleServerEvent);
  }

  TarabTable _initialTable() {
    return TarabTable(
      tableId: 'TBL-001',
      isPrivate: false,
      entryFee: 5000,
      seats: const [
        TableSeat(
          seatNumber: 1,
          playerId: 'P-101',
          playerName: 'أحمد',
          isConnected: true,
        ),
        TableSeat(
          seatNumber: 2,
          playerId: 'P-102',
          playerName: 'سارة',
          isConnected: true,
        ),
        TableSeat(
          seatNumber: 3,
          playerId: 'BOT-1',
          playerName: 'مرافق ذكي 1',
          isBot: true,
          isConnected: true,
        ),
        TableSeat(
          seatNumber: 4,
          playerId: 'BOT-2',
          playerName: 'مرافق ذكي 2',
          isBot: true,
          isConnected: true,
        ),
        TableSeat(
          seatNumber: 5,
        ),
      ],
    );
  }

  PlayerWallet _initialWallet() {
    return PlayerWallet(
      playerId: 'P-101',
      coins: 12000,
      debt: 2500,
      transactions: [
        WalletTransaction(
          type: 'REWARD',
          source: 'daily_checkin',
          amount: 5000,
          paidTowardsDebt: 2500,
          addedCoins: 2500,
          remainingDebt: 2500,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  void _handleServerEvent(Map<String, dynamic> event) {
    final type = event['type'] as String? ?? '';

    setState(() {
      if (type == 'WELCOME') {
        _connectionStatus = 'متصل بخادم TARAB';
      } else if (type == 'SOCKET_CLOSED' || type == 'SOCKET_ERROR') {
        _connectionStatus = 'انقطع الاتصال بالخادم';
      } else if (type == 'ERROR' || (type == 'JOIN_RESULT' && event['joined'] == false)) {
        _lastFeedback = event['reason'] as String? ??
            event['message'] as String? ??
            'تعذر تنفيذ العملية';
      } else if (type == 'JOIN_RESULT' && event['joined'] == true) {
        _lastFeedback = 'تم تسكين المقعد بنجاح (رقم المقعد: ${event['assignedSeat']})';
      } else if (type == 'WALLET_UPDATED') {
        _lastFeedback = 'تم تحديث المحفظة وتطبيق قواعد سداد الدين تلقائياً';
      } else if (type == 'ROUND_STARTED') {
        _lastFeedback = 'بدأت جولة الأوراق بنجاح';
      } else if (type == 'CARD_PLAYED') {
        _lastFeedback = 'تم لعب الورقة وتحديث الجولة';
      }

      if ((type == 'TABLE_CREATED' ||
              type == 'JOIN_RESULT' ||
              type == 'LEAVE_RESULT') &&
          event['table'] is Map<String, dynamic>) {
        _table = _parseTableFromJson(event['table'] as Map<String, dynamic>);
      }

      if ((type == 'ROUND_STARTED' || type == 'CARD_PLAYED') &&
          event['round'] is Map<String, dynamic>) {
        _round = event['round'] as Map<String, dynamic>;
      }

      if (event['wallet'] is Map<String, dynamic>) {
        _wallet = _parseWalletFromJson(event['wallet'] as Map<String, dynamic>);
      }
    });
  }

  TarabTable _parseTableFromJson(Map<String, dynamic> json) {
    final rawSeats = (json['seats'] as List<dynamic>? ?? []);
    final seats = rawSeats.map((item) {
      final seatMap = item as Map<String, dynamic>;
      return TableSeat(
        seatNumber: (seatMap['seatNumber'] as num?)?.toInt() ?? 1,
        playerId: seatMap['playerId'] as String?,
        playerName: seatMap['playerName'] as String?,
        isBot: seatMap['isBot'] as bool? ?? false,
        isConnected: seatMap['isConnected'] as bool? ?? false,
      );
    }).toList();

    return TarabTable(
      tableId: json['tableId'] as String? ?? _table.tableId,
      isPrivate: json['isPrivate'] as bool? ?? false,
      entryFee: (json['entryFee'] as num?)?.toInt() ?? _table.entryFee,
      seats: seats.isEmpty ? _table.seats : seats,
    );
  }

  PlayerWallet _parseWalletFromJson(Map<String, dynamic> json) {
    return PlayerWallet(
      playerId: json['playerId'] as String? ?? _wallet.playerId,
      coins: (json['coins'] as num?)?.toInt() ?? _wallet.coins,
      debt: (json['debt'] as num?)?.toInt() ?? _wallet.debt,
      transactions: _wallet.transactions,
    );
  }

  Future<void> _connectSocket() async {
    setState(() {
      _connectionStatus = 'جاري الاتصال...';
      _lastFeedback = null;
    });
    try {
      await _socketService.connect('ws://localhost:3000');
      setState(() {
        _connectionStatus = 'متصل بخادم TARAB';
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'تعذر الاتصال: $e';
      });
    }
  }

  void _sendCreateTable() {
    try {
      _socketService.createTable(
        tableId: _table.tableId,
        isPrivate: _table.isPrivate,
        entryFee: _table.entryFee,
      );
      setState(() {
        _lastFeedback = 'تم إرسال طلب إنشاء الطاولة (${_table.tableId})';
      });
    } catch (e) {
      setState(() {
        _lastFeedback = e.toString();
      });
    }
  }

  void _sendJoinBot() {
    try {
      final botIndex = _table.occupiedSeatsCount + 1;
      _socketService.joinTable(
        tableId: _table.tableId,
        playerId: 'BOT-$botIndex',
        playerName: 'مرافق ذكي $botIndex',
        isBot: true,
      );
    } catch (e) {
      setState(() {
        _lastFeedback = e.toString();
      });
    }
  }

  void _sendReward() {
    try {
      _socketService.applyReward(
        playerId: _wallet.playerId,
        amount: 3000,
        source: 'optional_ad',
      );
    } catch (e) {
      setState(() {
        _lastFeedback = e.toString();
      });
    }
  }

  void _sendStartRound() {
    try {
      _socketService.startRound(tableId: _table.tableId, cardsPerPlayer: 5);
    } catch (e) {
      setState(() {
        _lastFeedback = e.toString();
      });
    }
  }

  void _sendPlayCard(String cardId) {
    try {
      _socketService.playCard(
        tableId: _table.tableId,
        playerId: _wallet.playerId,
        cardId: cardId,
      );
    } catch (e) {
      setState(() {
        _lastFeedback = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _socketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = widget.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'طراب - TARAB' : 'TARAB'),
        actions: [
          TextButton(
            onPressed: widget.onToggleLanguage,
            child: Text(isArabic ? 'EN' : 'العربية'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isArabic
                  ? 'مرحباً بك في لعبة الورق طراب'
                  : 'Welcome to TARAB Card Game',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              isArabic
                  ? 'طاولة من 5 مقاعد • اتصال لحظي • شخصيات مخصصة'
                  : '5-Seat Table • Real-Time Play • Custom Characters',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isArabic
                          ? 'حالة الاتصال: $_connectionStatus'
                          : 'Socket: $_connectionStatus',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    ElevatedButton(
                      onPressed: _connectSocket,
                      child: Text(isArabic ? 'اتصال لحظي' : 'Connect'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _sendCreateTable,
                  child: Text(isArabic ? 'إنشاء طاولة' : 'Create Table'),
                ),
                OutlinedButton(
                  onPressed: _sendJoinBot,
                  child: Text(isArabic ? 'إضافة شخصية آلية' : 'Add Bot'),
                ),
                OutlinedButton(
                  onPressed: _sendReward,
                  child: Text(isArabic ? 'مكافأة (+3,000)' : 'Reward (+3,000)'),
                ),
              ],
            ),
            if (_lastFeedback != null) ...[
              const SizedBox(height: 10),
              Text(
                _lastFeedback!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            WalletSummaryCard(
              wallet: _wallet,
              entryFee: _table.entryFee,
              isArabic: isArabic,
            ),
            const SizedBox(height: 16),
            TableSeatsGrid(
              table: _table,
              isArabic: isArabic,
            ),
            const SizedBox(height: 16),
            RoundBoardWidget(
              round: _round,
              currentPlayerId: _wallet.playerId,
              isArabic: isArabic,
              onStartRound: _sendStartRound,
              onPlayCard: _sendPlayCard,
            ),
          ],
        ),
      ),
    );
  }
}
