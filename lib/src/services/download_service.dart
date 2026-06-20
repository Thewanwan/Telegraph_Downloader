import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../models/download_config.dart';
import '../models/album_progress.dart';
import '../models/download_result.dart';
import 'network_service.dart';
import 'page_parser.dart';

class DownloadService extends ChangeNotifier {
  bool _isDownloading = false;
  bool _isCancelled = false;
  List<AlbumProgress> _albums = [];
  DownloadResult _result = DownloadResult();
  String _currentLog = '';
  int _completedAlbums = 0;
  int _totalAlbums = 0;

  bool get isDownloading => _isDownloading;
  List<AlbumProgress> get albums => List.unmodifiable(_albums);
  DownloadResult get result => _result;
  String get currentLog => _currentLog;
  int get completedAlbums => _completedAlbums;
  int get totalAlbums => _totalAlbums;
  double get overallProgress =>
      _totalAlbums > 0 ? _completedAlbums / _totalAlbums : 0.0;

  void _log(String message) {
    _currentLog = message;
    notifyListeners();
  }

  void cancel() {
    _isCancelled = true;
    _log('正在取消...');
  }

  Future<DownloadResult> downloadAll(
    List<String> urls,
    String basePath,
    DownloadConfig config,
  ) async {
    _isDownloading = true;
    _isCancelled = false;
    _result = DownloadResult();
    _albums.clear();
    _completedAlbums = 0;
    _totalAlbums = urls.length;
    notifyListeners();

    final stopwatch = Stopwatch()..start();
    final networkService = NetworkService(config);

    try {
      for (int i = 0; i < urls.length; i++) {
        if (_isCancelled) {
          _log('已取消下载');
          break;
        }

        final url = urls[i].trim();
        if (url.isEmpty) continue;

        _log('[${i + 1}/${urls.length}] 正在解析: $url');
        _completedAlbums = i;
        notifyListeners();

        try {
          final html = await networkService.fetchPage(url);
          final title =
              PageParser.extractTitle(html, fallback: '未命名_${i + 1}');
          final imageUrls = PageParser.extractImageUrls(html);

          if (imageUrls.isEmpty) {
            _log('  ⚠ 未找到图片: $title');
            _result.skipped++;
            continue;
          }

          final album = AlbumProgress(
            title: title,
            url: url,
            totalImages: imageUrls.length,
            imageUrls: imageUrls,
            status: AlbumStatus.downloading,
          );
          _albums.add(album);
          _log('  📁 $title (${imageUrls.length} 张图片)');
          notifyListeners();

          final folder = p.join(basePath, title);
          await Directory(folder).create(recursive: true);

          final albumResult = await _downloadImages(
            imageUrls,
            folder,
            album,
            config,
            networkService,
          );

          _result.success++;
          _result.totalImages += albumResult.downloaded;
          _result.totalBytes += albumResult.totalBytes;

          album.downloaded = albumResult.downloaded;
          album.failed = albumResult.failed;
          album.status = albumResult.failed > 0
              ? AlbumStatus.failed
              : AlbumStatus.completed;
        } on Exception catch (e) {
          _log('  ❌ 错误: $e');
          _result.failed++;
        }
        notifyListeners();
      }
    } finally {
      networkService.close();
      _completedAlbums = _totalAlbums;
      stopwatch.stop();
      _result.elapsed = stopwatch.elapsedMilliseconds / 1000.0;
      _isDownloading = false;
      _log(_buildSummary());
      notifyListeners();
    }

    return _result;
  }

  Future<_AlbumDownloadResult> _downloadImages(
    List<String> urls,
    String folder,
    AlbumProgress album,
    DownloadConfig config,
    NetworkService networkService,
  ) async {
    int downloaded = 0;
    int failed = 0;
    int totalBytes = 0;
    final seenNames = <String, int>{};

    final semaphore = _Semaphore(config.maxWorkers);
    final futures = <Future>[];

    for (int idx = 0; idx < urls.length; idx++) {
      if (_isCancelled) break;

      final url = urls[idx];
      final path = _uniquePath(idx, url, folder, seenNames);

      await semaphore.acquire();
      final future = networkService
          .downloadImage(url, path,
              saveFormat: config.saveFormat, quality: config.imageQuality)
          .then((bytes) {
        downloaded++;
        totalBytes += bytes;
        album.downloaded = downloaded;
        album.failed = failed;
        notifyListeners();
      }).catchError((e) {
        failed++;
        album.downloaded = downloaded;
        album.failed = failed;
        notifyListeners();
      }).whenComplete(() => semaphore.release());

      futures.add(future);
    }

    await Future.wait(futures);
    return _AlbumDownloadResult(downloaded, failed, totalBytes);
  }

  String _uniquePath(
    int idx,
    String url,
    String folder,
    Map<String, int> seenNames,
  ) {
    final uri = Uri.parse(url);
    var name = p.basename(uri.path);
    if (name.isEmpty || name == '/') {
      name = 'image_$idx.jpg';
    }

    if (seenNames.containsKey(name)) {
      seenNames[name] = seenNames[name]! + 1;
      final ext = p.extension(name);
      final base = p.basenameWithoutExtension(name);
      name = '${base}_${seenNames[name]}$ext';
    } else {
      seenNames[name] = 0;
    }

    return p.join(folder, name);
  }

  String _buildSummary() {
    final r = _result;
    final buffer = StringBuffer('--- 下载完成 ---\n');
    buffer.writeln(
        '成功: ${r.success} | 失败: ${r.failed} | 跳过: ${r.skipped}');
    buffer.writeln(
        '图片: ${r.totalImages} 张 | 大小: ${_formatSize(r.totalBytes)}');
    buffer.writeln('耗时: ${_formatTime(r.elapsed)}');
    return buffer.toString();
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  static String _formatTime(double seconds) {
    if (seconds < 60) return '${seconds.toStringAsFixed(0)}秒';
    final m = (seconds / 60).floor();
    final s = (seconds % 60).floor();
    if (m < 60) return '${m}分${s}秒';
    final h = (m / 60).floor();
    final rm = m % 60;
    return '${h}时${rm}分${s}秒';
  }
}

class _AlbumDownloadResult {
  final int downloaded;
  final int failed;
  final int totalBytes;
  _AlbumDownloadResult(this.downloaded, this.failed, this.totalBytes);
}

class _Semaphore {
  int _count;
  final int _max;
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  _Semaphore(this._max) : _count = 0;

  Future<void> acquire() async {
    if (_count < _max) {
      _count++;
      return;
    }
    final completer = Completer<void>();
    _waitQueue.add(completer);
    await completer.future;
    _count++;
  }

  void release() {
    _count--;
    if (_waitQueue.isNotEmpty) {
      final next = _waitQueue.removeFirst();
      if (!next.isCompleted) {
        next.complete();
      }
    }
  }
}
