import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:simple_https_service/simple_https_service.dart';

/// (en) Internal helper that drives a single POST attempt with optional
/// timing control, exponential-backoff retry, ServerResponse formatting,
/// and caller-driven cancellation via [CancelToken].
/// Not exported from the public library.
///
/// (ja) タイミング制御・指数バックオフリトライ・ServerResponse整形・
/// [CancelToken]による呼び出し側からのキャンセルを1箇所にまとめた内部ヘルパーです。
/// 公開ライブラリからは公開されません。
///
/// * [validatedUrl] : Already-validated https URL.
/// * [send] : Closure that performs one HTTP send and returns the response.
/// Must construct any per-attempt resources internally so that retries
/// produce a fresh request each time. The closure receives the optional
/// [CancelToken] and must register the http.Client it creates via
/// [CancelToken.attachClient] so the request can be aborted mid-flight.
/// * [resType] : Response body formatting type.
/// * [adjustTiming] / [intervalMs] : See HttpsService.post documentation.
/// * [retryIf] / [maxRetries] / [baseDelay] / [maxJitter] :
/// See HttpsService.post documentation.
/// * [isExtraTimeoutError] : Optional predicate that classifies a caught
/// non-TimeoutException error as a timeout. Used by the native service to
/// treat SocketException (connection-level timeout) as a timeout.
/// * [cancelToken] : Optional token. When cancelled, the in-flight request
/// is aborted, pending TimingManager / backoff waits return early, and the
/// runner returns a ServerResponse with EnumServerResponseStatus.cancelled.
Future<ServerResponse> runPostWithRetry({
  required String validatedUrl,
  required Future<http.Response> Function(CancelToken? token) send,
  required EnumServerResponseType resType,
  required bool adjustTiming,
  required int intervalMs,
  bool Function(String url, ServerResponse res, Object? error)? retryIf,
  int? maxRetries,
  Duration? baseDelay,
  Duration? maxJitter,
  bool Function(Object e)? isExtraTimeoutError,
  CancelToken? cancelToken,
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
    if (cancelToken?.isCancelled == true) {
      return UtilServerResponse.cancelled();
    }

    if (attempt > 0) {
      final backoffMs = effectiveBaseDelayMs * (1 << (attempt - 1));
      final jitterMs = effectiveMaxJitterMs > 0
          ? random.nextInt(effectiveMaxJitterMs + 1)
          : 0;
      final delay = Duration(milliseconds: backoffMs + jitterMs);
      if (cancelToken != null) {
        await Future.any([Future.delayed(delay), cancelToken.whenCancelled]);
        if (cancelToken.isCancelled) {
          return UtilServerResponse.cancelled();
        }
      } else {
        await Future.delayed(delay);
      }
    }

    late ServerResponse result;
    Object? caughtError;

    try {
      if (adjustTiming) {
        final timingFuture =
            TimingManager().adjustTiming(intervalMs: intervalMs);
        if (cancelToken != null) {
          await Future.any([timingFuture, cancelToken.whenCancelled]);
          if (cancelToken.isCancelled) {
            return UtilServerResponse.cancelled();
          }
        } else {
          await timingFuture;
        }
      }
      final http.Response r = await send(cancelToken);
      if (r.statusCode >= 200 && r.statusCode <= 299) {
        result = UtilServerResponse.success(r, resType: resType);
      } else if (r.statusCode == 401) {
        result = UtilServerResponse.signInRequired(res: r, resType: resType);
      } else {
        result = UtilServerResponse.serverError(r, resType: resType);
      }
      caughtError = null;
    } on TimeoutException catch (e) {
      if (cancelToken?.isCancelled == true) {
        return UtilServerResponse.cancelled();
      }
      result = UtilServerResponse.timeout(e);
      caughtError = e;
    } catch (e) {
      if (cancelToken?.isCancelled == true) {
        return UtilServerResponse.cancelled();
      }
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
