import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/config_service.dart';
import '../models/download_config.dart';

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
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                '下载设置',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Save path
              Text('保存路径',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      config.savePath.isEmpty ? '未设置' : config.savePath,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final result =
                          await FilePicker.platform.getDirectoryPath(
                        dialogTitle: '选择保存路径',
                      );
                      if (result != null) {
                        config.setSavePath(result);
                      }
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('浏览'),
                  ),
                ],
              ),
              const Divider(),

              // Thread count
              _buildDropdown<int>(
                context,
                label: '线程数',
                value: dc.maxWorkers,
                items: [2, 4, 8, 12, 16, 20],
                onChanged: (v) {
                  if (v != null) {
                    config.setDownloadConfig(
                      DownloadConfig(
                        maxWorkers: v,
                        requestTimeout: dc.requestTimeout,
                        downloadTimeout: dc.downloadTimeout,
                        saveFormat: dc.saveFormat,
                        imageQuality: dc.imageQuality,
                      ),
                    );
                  }
                },
              ),

              // Request timeout
              _buildDropdown<int>(
                context,
                label: '请求超时（秒）',
                value: dc.requestTimeout,
                items: [5, 10, 15, 30, 60],
                onChanged: (v) {
                  if (v != null) {
                    config.setDownloadConfig(
                      DownloadConfig(
                        maxWorkers: dc.maxWorkers,
                        requestTimeout: v,
                        downloadTimeout: dc.downloadTimeout,
                        saveFormat: dc.saveFormat,
                        imageQuality: dc.imageQuality,
                      ),
                    );
                  }
                },
              ),

              // Save format
              _buildDropdown<String>(
                context,
                label: '保存格式',
                value: dc.saveFormat,
                items: ['original', 'JPG', 'PNG', 'WebP', 'BMP'],
                labels: ['保持原样', 'JPG', 'PNG', 'WebP', 'BMP'],
                onChanged: (v) {
                  if (v != null) {
                    config.setDownloadConfig(
                      DownloadConfig(
                        maxWorkers: dc.maxWorkers,
                        requestTimeout: dc.requestTimeout,
                        downloadTimeout: dc.downloadTimeout,
                        saveFormat: v,
                        imageQuality: dc.imageQuality,
                      ),
                    );
                  }
                },
              ),

              // Image quality (for JPG/WebP)
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
                      DownloadConfig(
                        maxWorkers: dc.maxWorkers,
                        requestTimeout: dc.requestTimeout,
                        downloadTimeout: dc.downloadTimeout,
                        saveFormat: dc.saveFormat,
                        imageQuality: v.toInt(),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // About
              Text('关于',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(
                'Telegraph Downloader v1.0\n'
                '跨平台 Telegraph 图册批量下载工具\n'
                '支持 Android / iOS / macOS / Windows / Linux',
                style: Theme.of(context).textTheme.bodySmall,
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
