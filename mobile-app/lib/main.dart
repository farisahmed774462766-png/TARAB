import 'package:flutter/material.dart';
import 'models/table_model.dart';
import 'widgets/table_seats_grid.dart';

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

class TarabHomeScreen extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onToggleLanguage;

  const TarabHomeScreen({
    super.key,
    required this.isArabic,
    required this.onToggleLanguage,
  });

  TarabTable _sampleTable() {
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

  @override
  Widget build(BuildContext context) {
    final table = _sampleTable();

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'طراب - TARAB' : 'TARAB'),
        actions: [
          TextButton(
            onPressed: onToggleLanguage,
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
            const SizedBox(height: 16),
            TableSeatsGrid(
              table: table,
              isArabic: isArabic,
            ),
          ],
        ),
      ),
    );
  }
}
