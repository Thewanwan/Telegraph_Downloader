class DownloadConfig {
  int maxWorkers;
  int requestTimeout;
  int downloadTimeout;
  int maxRetries;
  double retryBackoff;
  int chunkSize;
  String userAgent;
  String saveFormat;
  int imageQuality;

  DownloadConfig({
    this.maxWorkers = 8,
    this.requestTimeout = 15,
    this.downloadTimeout = 30,
    this.maxRetries = 3,
    this.retryBackoff = 0.5,
    this.chunkSize = 8192,
    this.userAgent =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    this.saveFormat = 'original',
    this.imageQuality = 95,
  });

  Map<String, dynamic> toJson() => {
        'maxWorkers': maxWorkers,
        'requestTimeout': requestTimeout,
        'downloadTimeout': downloadTimeout,
        'maxRetries': maxRetries,
        'retryBackoff': retryBackoff,
        'chunkSize': chunkSize,
        'userAgent': userAgent,
        'saveFormat': saveFormat,
        'imageQuality': imageQuality,
      };

  factory DownloadConfig.fromJson(Map<String, dynamic> json) {
    return DownloadConfig(
      maxWorkers: json['maxWorkers'] ?? 8,
      requestTimeout: json['requestTimeout'] ?? 15,
      downloadTimeout: json['downloadTimeout'] ?? 30,
      maxRetries: json['maxRetries'] ?? 3,
      retryBackoff: (json['retryBackoff'] ?? 0.5).toDouble(),
      chunkSize: json['chunkSize'] ?? 8192,
      userAgent: json['userAgent'] ??
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      saveFormat: json['saveFormat'] ?? 'original',
      imageQuality: json['imageQuality'] ?? 95,
    );
  }
}
