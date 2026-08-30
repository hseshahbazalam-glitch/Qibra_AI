// Conservative retries. Permanent 4xx / validation / auth are not retried.

class RetryPolicy {
  const RetryPolicy();

  static bool shouldRetry({
    int? httpStatus,
    bool timeout = false,
    bool networkFailure = false,
  }) {
    if (timeout || networkFailure) return true;
    if (httpStatus == null) return false;
    if (httpStatus >= 500 && httpStatus <= 599) return true;
    if (httpStatus == 429) return true;
    return false;
  }

  static Duration backoff(
    int attempt, {
    int maxMs = 30000,
    int jitterMs = 0,
  }) {
    final base = 250 * (1 << attempt.clamp(0, 6));
    return Duration(milliseconds: (base + jitterMs).clamp(250, maxMs));
  }

  static DateTime nextRetryAt(DateTime now, int attempt, {int jitterMs = 0}) {
    return now.add(backoff(attempt, jitterMs: jitterMs));
  }
}
