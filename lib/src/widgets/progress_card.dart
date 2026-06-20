import 'package:flutter/material.dart';
import '../models/album_progress.dart';

class ProgressCard extends StatelessWidget {
  final bool isDownloading;
  final List<AlbumProgress> albums;
  final double overallProgress;
  final int completedAlbums;
  final int totalAlbums;

  const ProgressCard({
    super.key,
    required this.isDownloading,
    required this.albums,
    required this.overallProgress,
    required this.completedAlbums,
    required this.totalAlbums,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDownloading ? Icons.downloading : Icons.download_done,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isDownloading
                      ? '下载进度 ($completedAlbums/$totalAlbums)'
                      : '下载状态',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            if (isDownloading) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: overallProgress,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
            if (albums.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...albums.map((album) => _buildAlbumRow(context, album)),
            ],
            if (!isDownloading && albums.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '输入链接后点击"开始下载"',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumRow(BuildContext context, AlbumProgress album) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              album.title,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: album.progress,
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              album.statusText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _statusColor(album.status, context),
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(AlbumStatus status, BuildContext context) {
    switch (status) {
      case AlbumStatus.waiting:
        return Theme.of(context).colorScheme.outline;
      case AlbumStatus.downloading:
        return Theme.of(context).colorScheme.primary;
      case AlbumStatus.completed:
        return Colors.green;
      case AlbumStatus.failed:
        return Colors.orange;
      case AlbumStatus.cancelled:
        return Colors.red;
    }
  }
}
