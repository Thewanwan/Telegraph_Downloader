enum AlbumStatus { waiting, downloading, completed, failed, cancelled }

class AlbumProgress {
  final String title;
  final String url;
  final int totalImages;
  int downloaded;
  int failed;
  AlbumStatus status;

  AlbumProgress({
    required this.title,
    required this.url,
    this.totalImages = 0,
    this.downloaded = 0,
    this.failed = 0,
    this.status = AlbumStatus.waiting,
  });

  double get progress =>
      totalImages > 0 ? downloaded / totalImages : 0.0;

  String get statusText {
    switch (status) {
      case AlbumStatus.waiting:
        return '等待中';
      case AlbumStatus.downloading:
        return '下载中 $downloaded/$totalImages';
      case AlbumStatus.completed:
        return '完成';
      case AlbumStatus.failed:
        return '部分失败 ($failed)';
      case AlbumStatus.cancelled:
        return '已取消';
    }
  }
}
