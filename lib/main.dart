import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/services/config_service.dart';
import 'app/services/download_service.dart';
import 'pages/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final configService = await ConfigService.create();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DownloadService()),
        ChangeNotifierProvider.value(value: configService),
      ],
      child: const TelegraphDownloaderApp(),
    ),
  );
}

class TelegraphDownloaderApp extends StatelessWidget {
  const TelegraphDownloaderApp({super.key});

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
          home: const HomePage(),
        );
      },
    );
  }
}
