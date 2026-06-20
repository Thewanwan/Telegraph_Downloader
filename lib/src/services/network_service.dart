import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/download_config.dart';

class NetworkService {
  final DownloadConfig config;
  late http.Client _client;

  NetworkService(this.config) {
    _client = http.Client();
  }

  Future<String> fetchPage(String url) async {
    int retries = 0;
    while (retries <= config.maxRetries) {
      try {
        final response = await _client
            .get(Uri.parse(url))
            .timeout(Duration(seconds: config.requestTimeout));
        if (response.statusCode == 200) return response.body;
        if (response.statusCode == 429 || response.statusCode >= 500) {
          retries++;
          if (retries > config.maxRetries) break;
          await _backoff(retries);
          continue;
        }
        throw HttpException('HTTP ${response.statusCode}');
      } on TimeoutException {
        retries++;
        if (retries > config.maxRetries) rethrow;
        await _backoff(retries);
      } on SocketException {
        retries++;
        if (retries > config.maxRetries) rethrow;
        await _backoff(retries);
      }
    }
    throw Exception('Max retries exceeded');
  }

  Future<int> downloadImage(
    String url,
    String savePath, {
    String saveFormat = 'original',
    int quality = 95,
  }) async {
    int retries = 0;
    while (retries <= config.maxRetries) {
      final file = File(savePath);
      try {
        final request = http.Request('GET', Uri.parse(url));
        final response = await _client
            .send(request)
            .timeout(Duration(seconds: config.downloadTimeout));

        if (response.statusCode == 200) {
          int totalBytes = 0;
          final sink = file.openWrite(mode: FileMode.write);
          await for (final chunk in response.stream) {
            sink.add(chunk);
            totalBytes += chunk.length;
          }
          await sink.close();
          return totalBytes;
        }
        if (response.statusCode == 429 || response.statusCode >= 500) {
          retries++;
          if (retries > config.maxRetries) break;
          _cleanup(file);
          await _backoff(retries);
          continue;
        }
        throw HttpException('HTTP ${response.statusCode}');
      } on TimeoutException {
        _cleanup(file);
        retries++;
        if (retries > config.maxRetries) rethrow;
        await _backoff(retries);
      } on SocketException {
        _cleanup(file);
        retries++;
        if (retries > config.maxRetries) rethrow;
        await _backoff(retries);
      } on HttpException {
        _cleanup(file);
        rethrow;
      }
    }
    throw Exception('Max retries exceeded');
  }

  void _backoff(int retry) =>
      Future.delayed(Duration(milliseconds: (config.retryBackoff * 1000 * retry).toInt()));

  void _cleanup(File file) {
    if (file.existsSync()) file.deleteSync();
  }

  void close() => _client.close();
}
