import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/config_service.dart';
import '../routes/app_routes.dart';

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
          home: AppRoutes.home,
        );
      },
    );
  }
}
