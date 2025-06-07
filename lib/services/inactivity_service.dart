class InactivityService {
  IdleDetector _detector;
  Duration timeout;
  VoidCallback onTimeout;

  void start() {
    _detector = IdleDetector(
      timeout: timeout,
      onTimeout: onTimeout,
    )..start();
  }

  void stop() {
    _detector?.stop();
  }

  void reset() {
    stop();
    start();
  }
} 