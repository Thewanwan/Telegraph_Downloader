class DownloadResult {
  int success;
  int failed;
  int skipped;
  int totalImages;
  double elapsed;
  int totalBytes;

  DownloadResult({
    this.success = 0,
    this.failed = 0,
    this.skipped = 0,
    this.totalImages = 0,
    this.elapsed = 0.0,
    this.totalBytes = 0,
  });
}
