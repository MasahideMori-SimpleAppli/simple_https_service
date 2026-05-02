import 'package:simple_https_service/simple_https_service.dart';

/// (en) Global retry configuration for HttpsService and HttpsServiceForNative.
/// This works with singletons.
///
/// (ja) HttpsServiceおよびHttpsServiceForNativeのグローバルリトライ設定です。
/// これはシングルトンで動作します。
class RetryConfig {
  static final RetryConfig _instance = RetryConfig._internal();

  RetryConfig._internal();

  factory RetryConfig() => _instance;

  /// (en) Maximum number of retries. Default is 3.
  ///
  /// (ja) 最大リトライ回数。デフォルトは3です。
  int maxRetries = 3;

  /// (en) Base delay for exponential backoff. Default is 1 second.
  /// The actual delay for attempt n is: baseDelay * 2^(n-1) + random jitter.
  ///
  /// (ja) 指数バックオフの基本待機時間。デフォルトは1秒です。
  /// n回目のリトライの実際の待機時間は baseDelay * 2^(n-1) + ランダムジッター です。
  Duration baseDelay = const Duration(seconds: 1);

  /// (en) Maximum random jitter added to each backoff delay. Default is 500ms.
  /// Set to Duration.zero to disable jitter.
  ///
  /// (ja) 各バックオフ遅延に加算される最大ランダムジッター。デフォルトは500msです。
  /// Duration.zeroを設定するとジッターを無効化できます。
  Duration maxJitter = const Duration(milliseconds: 500);

  /// (en) The default retry condition applied to all requests.
  /// Receives the request URL, the server response, and the caught error object
  /// (null if the request reached the server without throwing).
  /// Return true to retry, false to return the result as-is.
  /// If null, no retry is performed unless overridden per call.
  ///
  /// (ja) 全リクエストに適用されるデフォルトのリトライ条件です。
  /// リクエストURL、サーバー応答、キャッチされたエラーオブジェクト
  /// （サーバーに届いた場合はnull）を受け取ります。
  /// trueを返すとリトライ、falseを返すとそのまま結果を返します。
  /// nullの場合、呼び出し側で個別指定がない限りリトライを行いません。
  bool Function(String url, ServerResponse res, Object? error)?
      defaultCondition;
}
