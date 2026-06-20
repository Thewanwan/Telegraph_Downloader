import 'package:html/parser.dart' as parser;

class PageParser {
  static const String baseUrl = 'https://telegra.ph';

  static String extractTitle(String html, {String fallback = 'untitled'}) {
    final document = parser.parse(html);
    final h1 = document.querySelector('h1');
    String title = h1?.text.trim() ?? fallback;
    title = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '').trim();
    return title.isEmpty ? fallback : title;
  }

  static List<String> extractImageUrls(String html) {
    final document = parser.parse(html);
    final imgs = document.querySelectorAll('img');
    final urls = <String>[];

    for (final img in imgs) {
      final src = img.attributes['src'] ?? '';
      if (src.isNotEmpty) {
        final fullUrl = src.startsWith('/') ? '$baseUrl$src' : src;
        urls.add(fullUrl);
      }
    }
    return urls;
  }
}
