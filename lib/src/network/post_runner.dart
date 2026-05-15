import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:simple_https_service/simple_https_service.dart';

/// (en) Internal helper that drives a single POST attempt with optional
/// timing control, exponential-backoff retry, and ServerResponse formatting.
/// Not exported from the public library.
///
/// (ja) タイミング制御・指数バックオフリトライ・ServerResponse整形を
/// 1箇所にまとめた内部ヘルパーです。公開ライブラリからは公開されません。
///
/// * [validatedUrl] : Already-validated https URL.
/// * [send] : Closure that performs one HTTP send and returns the response.
/// Must construct any per-attempt resources internally so that retries
/// produce a fresh request each time.
/// * [resType] : Response body formatting type.
/// * [adjustTiming] / [intervalMs] : See HttpsService.post documentation.
/// * [retryIf] / [maxRetries] / [baseDelay] / [maxJitter] :
/// See HttpsService.post documentation.
/// * [isExtraTimeoutError] : Optional predicate that classifies a caught
/// non-TimeoutException error as a timeout. Used by the native service to
/// treat SocketException (connection-level timeout) as a timeout.
Future<ServerResponse> runPostWithRetry({
  required String validatedUrl,
  required Future<http.Response> Function() send,
  required EnumServerResponseType resType,
  required bool adjustTiming,
  required int intervalMs,
  bool Function(String url, ServerResponse res, Object? error)? retryIf,
  int? maxRetries,
  Duration? baseDelay,
  Duration? maxJitter,
  bool Function(Object e)? isExtraTimeoutError,
}) async {
  final effectiveRetryIf = retryIf ?? RetryConfig().defaultCondition;
  final effectiveMaxRetries =
      effectiveRetryIf != null ? (maxRetries ?? RetryConfig().maxRetries) : 0;
  final effectiveBaseDelayMs =
      (baseDelay ?? RetryConfig().baseDelay).inMilliseconds;
  final effectiveMaxJitterMs =
      (maxJitter ?? RetryConfig().maxJitter).inMilliseconds;
  final random = Random();

  for (int attempt = 0; attempt <= effectiveMaxRetries; attempt++) {
    if (attempt > 0) {
      final backoffMs = effectiveBaseDelayMs * (1 << (attempt - 1));
      final jitterMs = effectiveMaxJitterMs > 0
          ? random.nextInt(effectiveMaxJitterMs + 1)
          : 0;
      await Future.delayed(Duration(milliseconds: backoffMs + jitterMs));
    }

    late ServerResponse result;
    Object? caughtError;

    try {
      if (adjustTiming) {
        await TimingManager().adjustTiming(intervalMs: intervalMs);
      }
      final http.Response r = await send();
      if (r.statusCode >= 200 && r.statusCode <= 299) {
        result = UtilServerResponse.success(r, resType: resType);
      } else if (r.statusCode == 401) {
        result = UtilServerResponse.signInRequired(res: r, resType: resType);
      } else {
        result = UtilServerResponse.serverError(r, resType: resType);
      }
      caughtError = null;
    } on TimeoutException catch (e) {
      result = UtilServerResponse.timeout(e);
      caughtError = e;
    } catch (e) {
      if (isExtraTimeoutError != null && isExtraTimeoutError(e)) {
        result = UtilServerResponse.timeout(e);
      } else {
        result = UtilServerResponse.otherError(e);
      }
      caughtError = e;
    }

    if (effectiveRetryIf == null ||
        attempt >= effectiveMaxRetries ||
        !effectiveRetryIf(validatedUrl, result, caughtError)) {
      return result;
    }
  }

  throw StateError('Unexpected end of retry loop');
}
