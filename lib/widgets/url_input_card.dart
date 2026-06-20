import 'package:flutter/material.dart';

class UrlInputCard extends StatelessWidget {
  final TextEditingController controller;

  const UrlInputCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '链接列表（每行一个）',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 4,
              minLines: 2,
              decoration: const InputDecoration(
                hintText: '在此输入 telegra.ph 链接...\n多个链接请换行分隔',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
