class Formatters {
  static String formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  static String formatDuration(Duration duration) {
    if (duration.inSeconds < 60) return '${duration.inSeconds}秒';
    final m = duration.inMinutes;
    final s = duration.inSeconds % 60;
    if (m < 60) return '${m}分${s}秒';
    final h = duration.inHours;
    return '${h}时${m % 60}分${s}秒';
  }

  static String formatTime(double seconds) {
    if (seconds < 60) return '${seconds.toStringAsFixed(0)}秒';
    final m = (seconds / 60).floor();
    final s = (seconds % 60).floor();
    if (m < 60) return '${m}分${s}秒';
    final h = (m / 60).floor();
    return '${h}时${m % 60}分${s}秒';
  }

  static String formatProgress(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }
}
