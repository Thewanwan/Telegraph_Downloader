import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/services/config_service.dart';
import 'app/services/download_service.dart';
import 'app/services/update_service.dart';
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

class TelegraphDownloaderApp extends StatefulWidget {
  const TelegraphDownloaderApp({super.key});

  @override
  State<TelegraphDownloaderApp> createState() => _TelegraphDownloaderAppState();
}

class _TelegraphDownloaderAppState extends State<TelegraphDownloaderApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUpdate();
    });
  }

  Future<void> _checkUpdate() async {
    final info = await UpdateService.checkForUpdate('1.0.3');
    if (info != null && mounted) {
      UpdateService.showUpdateDialog(context, info);
    }
  }

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
