import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../app/services/config_service.dart';
import '../../app/services/update_service.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigService>();
    final dc = config.downloadConfig;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('下载设置',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              Text('保存路径',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              FutureBuilder<String>(
                future: config.getEffectiveSavePath(),
                builder: (ctx, snap) {
                  final path = snap.data ?? '加载中...';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceVariant
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          path,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              final result =
                                  await FilePicker.platform
                                      .getDirectoryPath(
                                dialogTitle: '选择保存路径',
                              );
                              if (result != null) {
                                config.setSavePath(result);
                              }
                            },
                            icon: const Icon(Icons.folder_open, size: 18),
                            label: const Text('选择路径'),
                          ),
                          const SizedBox(width: 8),
                          if (config.savePath.isNotEmpty)
                            FilledButton.tonalIcon(
                              onPressed: () {
                                config.setSavePath('');
                              },
                              icon: const Icon(Icons.restore, size: 18),
                              label: const Text('恢复默认'),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const Divider(),

              _buildDropdown<int>(
                context,
                label: '线程数',
                value: dc.maxWorkers,
                items: const [2, 4, 8, 12, 16, 20],
                labels: null,
                onChanged: (v) {
                  if (v != null) {
                    config.setDownloadConfig(dc.copyWith(maxWorkers: v));
                  }
                },
              ),

              _buildDropdown<int>(
                context,
                label: '请求超时（秒）',
                value: dc.requestTimeout,
                items: const [5, 10, 15, 30, 60],
                labels: null,
                onChanged: (v) {
                  if (v != null) {
                    config.setDownloadConfig(
                        dc.copyWith(requestTimeout: v));
                  }
                },
              ),

              _buildDropdown<String>(
                context,
                label: '保存格式',
                value: dc.saveFormat,
                items: const [
                  'original',
                  'JPG',
                  'PNG',
                  'WebP',
                  'BMP'
                ],
                labels: const ['保持原样', 'JPG', 'PNG', 'WebP', 'BMP'],
                onChanged: (v) {
                  if (v != null) {
                    config
                        .setDownloadConfig(dc.copyWith(saveFormat: v));
                  }
                },
              ),

              if (dc.saveFormat == 'JPG' || dc.saveFormat == 'WebP')
                _buildSlider(
                  context,
                  label: '图片质量',
                  value: dc.imageQuality.toDouble(),
                  min: 10,
                  max: 100,
                  divisions: 9,
                  onChanged: (v) {
                    config.setDownloadConfig(
                        dc.copyWith(imageQuality: v.toInt()));
                  },
                ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              Text('关于',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(
                'Telegraph Downloader v1.0.3\n'
                '跨平台 Telegraph 图册批量下载工具\n'
                '支持 Android / iOS / macOS / Windows / Linux',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('正在检查更新...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    final info =
                        await UpdateService.checkForUpdate('1.0.3');
                    if (!context.mounted) return;
                    if (info != null) {
                      UpdateService.showUpdateDialog(context, info);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('当前已是最新版本')),
                      );
                    }
                  },
                  icon: const Icon(Icons.system_update),
                  label: const Text('检查更新'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdown<T>(
    BuildContext context, {
    required String label,
    required T value,
    required List<T> items,
    List<String>? labels,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          DropdownButton<T>(
            value: value,
            items: List.generate(items.length, (i) {
              return DropdownMenuItem(
                value: items[i],
                child: Text(labels != null ? labels[i] : '${items[i]}'),
              );
            }),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${value.toInt()}',
              style: Theme.of(context).textTheme.bodyMedium),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
