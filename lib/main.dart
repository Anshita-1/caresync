import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/upload_report_screen.dart';
import 'screens/reminder_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/voice_assistant_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize(); // Make sure this is STATIC
  await ReminderNotificationService.init();
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();


  print("Env file loading from: ${Directory.current.path}");
  await dotenv.load(fileName: "assets/.env");

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.light;

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Duper Health App',
      debugShowCheckedModeBanner: false,

      // ─── Localization ────────────────────────────────────
      locale: _locale,
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('mr'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ─── Themes ──────────────────────────────────────────
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
      ),

      // ─── Routes ──────────────────────────────────────────
      initialRoute: '/',
      routes: {
        '/': (ctx) => SplashScreen(setLocale: setLocale),
        '/login': (ctx) => const LoginScreen(),
        '/register': (ctx) => const RegisterScreen(),
        '/home': (ctx) => HomeScreen(
          setLocale: setLocale,
          setThemeMode: setThemeMode,
        ),
        '/profile': (ctx) => ProfileScreen(
          setLocale: setLocale,
          setThemeMode: setThemeMode,
        ),
        '/upload': (ctx) => const UploadReportScreen(),
        '/reminder': (ctx) => const ReminderScreen(),
        '/chatbot': (ctx) => const ChatbotScreen(),
        '/voice': (ctx) => const VoiceAssistantScreen(),
      },
    );
  }
}
