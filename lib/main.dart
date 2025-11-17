import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_localization/easy_localization.dart';

import 'providers/expense_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/transactions_screen.dart';
import 'firebase_options.dart';
import '../services/expense_categorizer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Inicialización de Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await ExpenseCategorizer().loadModel();

  // Cargar preferencia de tema antes de ejecutar la app
  final themeProvider = ThemeProvider();
  await themeProvider.loadThemePreference();

  runApp(
    EasyLocalization(
      // ✅ Agregamos los locales exactos para inglés y español
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('es', 'ES'),
      ],

      // ✅ Ruta correcta donde están los JSON
      path: 'assets/lang', // 📂 Asegúrate de que exista esta carpeta

      fallbackLocale: const Locale('es', 'ES'),
      saveLocale: true, // ✅ guarda el idioma seleccionado

      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ExpenseProvider()),
          ChangeNotifierProvider(create: (_) => themeProvider),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: tr('app_title'),
      debugShowCheckedModeBanner: false,

      // 🌍 Configuración de localización
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // 🎨 Configuración de temas
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey[900],
      ),

      // 🚀 Rutas
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const HomeScreen(),
        '/add': (context) => const AddTransactionScreen(),
        '/summary': (context) => const SummaryScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/transactions': (context) => const TransactionsScreen(),
      },
    );
  }
}
