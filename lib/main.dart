import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/services/download_service.dart';
import 'src/services/config_service.dart';
import 'src/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final configService = await ConfigService.create();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DownloadService()),
        ChangeNotifierProvider.value(value: configService),
      ],
      child: const TelegraphApp(),
    ),
  );
}

class TelegraphApp extends StatelessWidget {
  const TelegraphApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigService>(
      builder: (context, config, _) {
        return MaterialApp(
          title: 'Telegraph Downloader',
          debugShowCheckedModeBanner: false,
          themeMode: config.themeMode,
          theme: ThemeData(
            colorSchemeSeed: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
