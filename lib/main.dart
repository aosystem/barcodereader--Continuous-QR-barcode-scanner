import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:barcodereader/l10n/app_localizations.dart';
import 'package:barcodereader/model.dart';
import 'package:barcodereader/home_page.dart';
import 'package:barcodereader/theme_mode_number.dart';
import 'package:barcodereader/loading_screen.dart';
import 'package:barcodereader/parse_locale_tag.dart';
import 'package:barcodereader/scan_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  ));
  MobileAds.instance.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ScanProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});
  @override
  State<MainApp> createState() => MainAppState();
}

class MainAppState extends State<MainApp> {
  ThemeMode themeMode = ThemeMode.light;
  Locale? locale;
  bool _isReady = false;
  Color seedColor = Colors.purple;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  void _initState() async {
    await Model.ensureReady();
    themeMode = ThemeModeNumber.numberToThemeMode(Model.themeNumber);
    locale = parseLocaleTag(Model.languageCode);
    setState(() {
      _isReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: LoadingScreen(),
          ),
        ),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainHomePage(),
    );
  }
}
