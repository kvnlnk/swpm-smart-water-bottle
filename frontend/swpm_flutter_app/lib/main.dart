import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:swpm_flutter_app/pages/main_page.dart';
import 'package:swpm_flutter_app/pages/sign_in.dart';
import 'package:swpm_flutter_app/store/bluetooth_device_data.dart';

import 'package:swpm_flutter_app/store/user_data.dart';
import 'package:swpm_flutter_app/store/water_data.dart';
import 'package:swpm_flutter_app/store/drinking_history_data.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserDataNotifier()),
        ChangeNotifierProvider(create: (_) => WaterDataNotifier()),
        ChangeNotifierProvider(create: (_) => DrinkingHistoryDataNotifier()),
        ChangeNotifierProvider(create: (_) => BluetoothDeviceDataNotifier()),
      ],
      child: const MyApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Water Bottle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 22, 135, 188),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SignIn(),
        '/main': (context) => const MainPage(),
      },
    );
  }
}
