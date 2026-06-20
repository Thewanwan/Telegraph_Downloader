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
        if (response.statusCode == 200) {
          return response.body;
        }
        if (response.statusCode == 429) {
          retries++;
          await Future.delayed(
              Duration(milliseconds: (config.retryBackoff * 1000 * retries).toInt()));
          continue;
        }
        throw HttpException('HTTP ${response.statusCode}');
      } on TimeoutException {
        retries++;
        if (retries > config.maxRetries) rethrow;
        await Future.delayed(
            Duration(milliseconds: (config.retryBackoff * 1000 * retries).toInt()));
      } on SocketException {
        retries++;
        if (retries > config.maxRetries) rethrow;
        await Future.delayed(
            Duration(milliseconds: (config.retryBackoff * 1000 * retries).toInt()));
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
      try {
        final request = http.Request('GET', Uri.parse(url));
        final response = await _client.send(request).timeout(
            Duration(seconds: config.downloadTimeout));

        if (response.statusCode == 200) {
          final file = File(savePath);
          int totalBytes = 0;
          await response.stream.forEach((chunk) {
            file.writeAsBytesSync(chunk, mode: FileMode.append);
            totalBytes += chunk.length;
          });
          return totalBytes;
        }
        throw HttpException('HTTP ${response.statusCode}');
      } on TimeoutException {
        retries++;
        if (retries > config.maxRetries) rethrow;
        await Future.delayed(
            Duration(milliseconds: (config.retryBackoff * 1000 * retries).toInt()));
      } on SocketException {
        retries++;
        if (retries > config.maxRetries) rethrow;
        await Future.delayed(
            Duration(milliseconds: (config.retryBackoff * 1000 * retries).toInt()));
      }
    }
    throw Exception('Max retries exceeded');
  }

  void close() {
    _client.close();
  }
}
