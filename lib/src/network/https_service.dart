import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:simple_https_service/simple_https_service.dart';

class HttpsService {
  /// (en) Build the https and POST it.
  ///
  /// (ja) Httpsを構築してPOSTします。
  /// このメソッドは「200 <= statusCode <= 299」の時、
  /// EnumServerResponseStatus.successを持つ通信成功時のオブジェクトを返します。
  /// また、401ではEnumServerResponseStatus.signInRequiredを、
  /// それ以外の場合は400番台でも500番台でもEnumServerResponseStatus.serverErrorを、
  /// 通信時のタイムアウトはEnumServerResponseStatus.timeoutを、
  /// その他の未知のエラーはEnumServerResponseStatus.otherErrorとしてマークします。
  ///
  /// * [url] : The URL to post to. Only https is permitted
  /// anything else will return an error response.
  /// * [body] : The data passed in the Map will be automatically
  /// encoded according to the enum specification.
  /// * [type] : Data passed in the map and the http headers are automatically
  /// encoded according to the enum specification.
  /// * [jwt] : The jwt. It is inserted into the Authorization header.
  /// * [timeout] : The response timeout.
  /// * [adjustTiming] : Specify true to automatically adjust the timing.
  /// * [intervalMs] : The minimum interval between calls that is
  /// automatically adjusted if adjustTiming is True.
  /// If consecutive calls are made earlier than this,
  /// they will wait until this interval before being executed.
  /// The unit is milliseconds.
  /// * [resType] : Formatting the return value from the server.
  ///
  /// The return value will be formatted as follows:
  ///
  /// For json: ServerResponse.resBody will contain the JSON encoded
  /// return value.
  ///
  /// For byte: ServerResponse.resBody will contain the return value in the
  /// format { "r" : Uint8list }.
  ///
  /// For text: ServerResponse.resBody will contain the return value in the
  /// format { "r" : UTF-8 text }.
  /// * [charset] : Use this when you want to explicitly specify the charset in
  /// the HTTP header. If null, it will automatically be set to utf-8. Also,
  /// if you enter an empty string, no specification will be made.
  /// * [retryIf] : Per-call retry condition. Overrides RetryConfig.defaultCondition
  /// when not null. Receives the URL, ServerResponse, and the caught error
  /// (null if the server responded without throwing). Return true to retry.
  /// * [maxRetries] : Per-call override for RetryConfig.maxRetries.
  /// * [baseDelay] : Per-call override for RetryConfig.baseDelay.
  /// * [maxJitter] : Per-call override for RetryConfig.maxJitter.
  static Future<ServerResponse> post(
      String url, Map<String, dynamic> body, EnumPostEncodeType type,
      {String? jwt,
      Duration timeout = const Duration(seconds: 30),
      bool adjustTiming = true,
      int intervalMs = 1200,
      EnumServerResponseType resType = EnumServerResponseType.json,
      String? charset,
      bool Function(String url, ServerResponse res, Object? error)? retryIf,
      int? maxRetries,
      Duration? baseDelay,
      Duration? maxJitter}) async {
    Map<String, String> headers = {};
    if (jwt != null) {
      headers['Authorization'] = 'Bearer $jwt';
    }
    switch (type) {
      case EnumPostEncodeType.urlEncoded:
        if (charset == null) {
          headers['Content-Type'] =
              'application/x-www-form-urlencoded; charset=utf-8';
        } else if (charset == "") {
          headers['Content-Type'] = 'application/x-www-form-urlencoded';
        } else {
          headers['Content-Type'] =
              'application/x-www-form-urlencoded; charset=$charset';
        }
        return customPost(url, Uri(queryParameters: body).query, headers,
            timeout: timeout,
            adjustTiming: adjustTiming,
            intervalMs: intervalMs,
            resType: resType,
            retryIf: retryIf,
            maxRetries: maxRetries,
            baseDelay: baseDelay,
            maxJitter: maxJitter);
      case EnumPostEncodeType.json:
        if (charset == null) {
          headers['Content-Type'] = 'application/json; charset=utf-8';
        } else if (charset == "") {
          headers['Content-Type'] = 'application/json';
        } else {
          headers['Content-Type'] = 'application/json; charset=$charset';
        }
        return customPost(url, jsonEncode(body), headers,
            timeout: timeout,
            adjustTiming: adjustTiming,
            intervalMs: intervalMs,
            resType: resType,
            retryIf: retryIf,
            maxRetries: maxRetries,
            baseDelay: baseDelay,
            maxJitter: maxJitter);
    }
  }

  /// (en) Build the https and POST it.
  /// This is a more customizable version, if you want a quicker experience
  /// you can use post function instead.
  ///
  /// (ja) Httpsを構築してPOSTします。
  /// これはカスタマイズ性を高めたバージョンで、簡単に利用したい場合は代わりにpostが使えます。
  /// このメソッドは「200 <= statusCode <= 299」の時、
  /// EnumServerResponseStatus.successを持つ通信成功時のオブジェクトを返します。
  /// また、401ではEnumServerResponseStatus.signInRequiredを、
  /// それ以外の場合は400番台でも500番台でもEnumServerResponseStatus.serverErrorを、
  /// 通信時のタイムアウトはEnumServerResponseStatus.timeoutを、
  /// その他の未知のエラーはEnumServerResponseStatus.otherErrorとしてマークします。
  ///
  /// * [url] : The URL to post to. Only https is permitted
  /// anything else will return an error response.
  /// * [body] : Map&lt;String, dynamic&gt;, Json encoded string, or List&lt;int&gt;.
  /// * [headers] : HTTP headers.
  /// * [encoding] : The data encoding.
  /// * [timeout] : The response timeout.
  /// * [adjustTiming] : Specify true to automatically adjust the timing.
  /// * [intervalMs] : The minimum interval between calls that is
  /// automatically adjusted if adjustTiming is True.
  /// If consecutive calls are made earlier than this,
  /// they will wait until this interval before being executed.
  /// The unit is milliseconds.
  /// * [resType] : Formatting the return value from the server.
  ///
  /// The return value will be formatted as follows:
  ///
  /// For json: ServerResponse.resBody will contain the JSON encoded return value.
  ///
  /// For byte: ServerResponse.resBody will contain the return value in the format { "r" : Uint8list }.
  ///
  /// For text: ServerResponse.resBody will contain the return value in the format { "r" : UTF-8 text }.
  /// * [retryIf] : Per-call retry condition. Overrides RetryConfig.defaultCondition
  /// when not null. Receives the URL, ServerResponse, and the caught error
  /// (null if the server responded without throwing). Return true to retry.
  /// * [maxRetries] : Per-call override for RetryConfig.maxRetries.
  /// * [baseDelay] : Per-call override for RetryConfig.baseDelay.
  /// * [maxJitter] : Per-call override for RetryConfig.maxJitter.
  static Future<ServerResponse> customPost(
      String url, Object? body, Map<String, String> headers,
      {Encoding? encoding,
      Duration timeout = const Duration(seconds: 30),
      bool adjustTiming = true,
      int intervalMs = 1200,
      EnumServerResponseType resType = EnumServerResponseType.json,
      bool Function(String url, ServerResponse res, Object? error)? retryIf,
      int? maxRetries,
      Duration? baseDelay,
      Duration? maxJitter}) async {
    final String httpsURL = UtilCheckURL.validateHttpsUrl(url);

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
        final http.Response r = await http
            .post(Uri.parse(httpsURL),
                headers: headers, body: body, encoding: encoding)
            .timeout(timeout);
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
        result = UtilServerResponse.otherError(e);
        caughtError = e;
      }

      if (effectiveRetryIf == null ||
          attempt >= effectiveMaxRetries ||
          !effectiveRetryIf(httpsURL, result, caughtError)) {
        return result;
      }
    }

    throw StateError('Unexpected end of retry loop');
  }
}
