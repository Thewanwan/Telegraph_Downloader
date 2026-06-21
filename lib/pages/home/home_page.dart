import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/services/download_service.dart';
import '../../app/services/config_service.dart';
import '../../widgets/url_input_card.dart';
import '../../widgets/progress_card.dart';
import '../../widgets/log_card.dart';
import '../../widgets/settings_sheet.dart';
import '../../widgets/history_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final _urlController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _urlController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  Future<void> _checkClipboard() async {
    final downloadService = context.read<DownloadService>();
    if (downloadService.isDownloading) return;

    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text ?? '';
      if (text.contains('telegra.ph/')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('检测到剪贴板中的 Telegraph 链接'),
            action: SnackBarAction(
              label: '粘贴',
              onPressed: () {
                final current = _urlController.text;
                if (current.isEmpty) {
                  _urlController.text = text;
                } else {
                  _urlController.text = '$current\n$text';
                }
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {}
  }

  List<String> _parseUrls(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Future<void> _startDownload() async {
    final config = context.read<ConfigService>();
    final downloadService = context.read<DownloadService>();

    if (downloadService.isDownloading) return;

    final urls = _parseUrls(_urlController.text);
    if (urls.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入至少一个链接')),
      );
      return;
    }

    final savePath = await config.getEffectiveSavePath();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('保存到: $savePath'),
        duration: const Duration(seconds: 2),
      ),
    );

    final result = await downloadService.downloadAll(
      urls,
      savePath,
      config.downloadConfig,
    );

    if (mounted) {
      config.addHistory({
        'urls': urls,
        'path': savePath,
        'time': DateTime.now().toIso8601String(),
        'success': result.success,
        'failed': result.failed,
        'images': result.totalImages,
        'bytes': result.totalBytes,
        'elapsed': result.elapsed,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '下载完成: ${result.success} 个图册, ${result.totalImages} 张图片',
          ),
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    final downloadService = context.read<DownloadService>();
    if (!downloadService.isDownloading) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('正在下载中，确认退出吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              downloadService.cancel();
              Navigator.pop(ctx, true);
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final downloadService = context.watch<DownloadService>();

    return PopScope(
      canPop: !downloadService.isDownloading,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await _onWillPop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Telegraph 图片下载器'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: () => context.read<ConfigService>().toggleTheme(),
              tooltip: '切换主题',
            ),
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => HistoryDialog(
                  onRedownload: (urls) {
                    _urlController.text = urls;
                  },
                ),
              ),
              tooltip: '历史记录',
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const SettingsSheet(),
              ),
              tooltip: '设置',
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                UrlInputCard(controller: _urlController),
                const SizedBox(height: 12),
                ProgressCard(
                  isDownloading: downloadService.isDownloading,
                  albums: downloadService.albums,
                  overallProgress: downloadService.overallProgress,
                  completedAlbums: downloadService.completedAlbums,
                  totalAlbums: downloadService.totalAlbums,
                ),
                const SizedBox(height: 12),
              Expanded(
                child: LogCard(
                  log: downloadService.currentLog,
                  logHistory: downloadService.logHistory,
                  scrollController: _scrollController,
                ),
              ),
                const SizedBox(height: 12),
                _buildActionButtons(downloadService),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(DownloadService service) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: service.isDownloading ? null : _startDownload,
            icon: const Icon(Icons.download),
            label: const Text('开始下载'),
          ),
        ),
        if (service.isDownloading) ...[
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: service.cancel,
              icon: const Icon(Icons.stop_circle, color: Colors.red),
              label: const Text('取消', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ],
    );
  }
}
