import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'app/services/config_service.dart';
import 'app/services/download_service.dart';

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
