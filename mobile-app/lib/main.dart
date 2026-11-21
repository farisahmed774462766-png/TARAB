import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isArabic
                    ? 'مرحباً بك في لعبة الورق طراب'
                    : 'Welcome to TARAB Card Game',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isArabic
                    ? 'طاولة من 5 مقاعد • اتصال لحظي • شخصيات مخصصة'
                    : '5-Seat Table • Real-Time Play • Custom Characters',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
