import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
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

class _HomePageState extends State<HomePage> {
  final _urlController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _urlController.dispose();
    _scrollController.dispose();
    super.dispose();
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

    String savePath = config.savePath;
    if (savePath.isEmpty) {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择保存路径',
      );
      if (result == null) return;
      savePath = result;
      config.setSavePath(savePath);
    }

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloadService = context.watch<DownloadService>();

    return Scaffold(
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
              builder: (_) => const HistoryDialog(),
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
                  scrollController: _scrollController,
                ),
              ),
              const SizedBox(height: 12),
              _buildActionButtons(downloadService),
            ],
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
