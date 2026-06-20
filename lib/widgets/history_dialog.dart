import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/services/config_service.dart';

class HistoryDialog extends StatelessWidget {
  const HistoryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigService>();

    return AlertDialog(
      title: const Text('下载历史'),
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
                  return ListTile(
                    leading: const Icon(Icons.download_done),
                    title: Text('${entry['success'] ?? 0} 个图册'),
                    subtitle: Text('$timeStr | ${(entry['images'] ?? 0)} 张图片'),
                    dense: true,
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            config.clearHistory();
            Navigator.pop(context);
          },
          child: const Text('清空'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
