import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/services/config_service.dart';

class HistoryDialog extends StatelessWidget {
  final void Function(String urls)? onRedownload;

  const HistoryDialog({super.key, this.onRedownload});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigService>();

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('下载历史'),
          if (config.history.isNotEmpty)
            TextButton(
              onPressed: () {
                config.clearHistory();
              },
              child: const Text('清空',
                  style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: config.history.isEmpty
            ? const Center(child: Text('暂无记录'))
            : ListView.builder(
                itemCount: config.history.length,
                itemBuilder: (ctx, i) {
                  final entry = config.history[i];
                  final time = entry['time']?.toString() ?? '';
                  final timeStr = time.length >= 19
                      ? time.substring(0, 19).replaceAll('T', ' ')
                      : time;
                  final urls = entry['urls'] as List? ?? [];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        '${entry['success'] ?? 0} 个图册 | ${(entry['images'] ?? 0)} 张图片',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '$timeStr | ${urls.length} 个链接',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall,
                          ),
                          if (urls.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            ...urls.take(3).map(
                                  (url) => Text(
                                    url.toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                  ),
                                ),
                            if (urls.length > 3)
                              Text(
                                '... 还有 ${urls.length - 3} 个链接',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall,
                              ),
                          ],
                        ],
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.download,
                            size: 20),
                        tooltip: '重新下载',
                        onPressed: () {
                          final urlText =
                              urls.map((e) => e.toString()).join('\n');
                          Navigator.pop(context);
                          onRedownload?.call(urlText);
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
