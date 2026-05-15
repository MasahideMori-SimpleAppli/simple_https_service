import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http_parser/http_parser.dart';
import 'package:simple_https_service/simple_https_service.dart';
import 'package:simple_https_service/src/network/post_runner.dart';

class HttpsServiceForNative {
  /// (en) Build the https and POST it.
  /// This class is not available in Flutter web.
  /// When "200 <= statusCode <= 299", this method returns an object with
  /// EnumServerResponseStatus.success when communication was successful.
  /// In addition, for 401, it marks　EnumServerResponseStatus.signInRequired,
  /// for all other errors, whether the error is in the 400 or 500 range,
  /// it marks EnumServerResponseStatus.serverError,
  /// a communication timeout is marked as EnumServerResponseStatus.timeout,
  /// and other unknown errors are marked as EnumServerResponseStatus.otherError.
  /// A request cancelled via [cancelToken] is marked as
  /// EnumServerResponseStatus.cancelled.
  ///
  /// (ja) Httpsを構築してPOSTします。
  /// このクラスはFlutter webでは利用できません。
  /// このメソッドは「200 <= statusCode <= 299」の時、
  /// EnumServerResponseStatus.successを持つ通信成功時のオブジェクトを返します。
  /// また、401ではEnumServerResponseStatus.signInRequiredを、
  /// それ以外の場合は400番台でも500番台でもEnumServerResponseStatus.serverErrorを、
  /// 通信時のタイムアウトはEnumServerResponseStatus.timeoutを、
  /// その他の未知のエラーはEnumServerResponseStatus.otherErrorとしてマークします。
  /// [cancelToken]によりキャンセルされた場合はEnumServerResponseStatus.cancelledを返します。
  ///
  /// * [url] : The URL to post to. Only https is permitted;
  /// anything else will return an error response.
  /// * [body] : The data passed in the Map will be automatically
  /// encoded according to the enum specification.
  /// * [type] : Data passed in the map and the http headers are automatically
  /// encoded according to the enum specification.
  /// * [jwt] : The jwt. It is inserted into the Authorization header.
  /// * [badCertificateCallback] : Returns true if you are using a local server
  /// that uses a self-signed certificate.
  /// * [connectionTimeout] : The connection timeout.
  /// * [responseTimeout] : The response timeout.
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
  /// * [cancelToken] : Optional token used to cancel this request. The same
  /// token can be shared across multiple requests to cancel them at once.
  static Future<ServerResponse> post(
      String url, Map<String, dynamic> body, EnumPostEncodeType type,
      {String? jwt,
      bool Function(X509Certificate cert, String host, int port)?
          badCertificateCallback,
      Duration connectionTimeout = const Duration(seconds: 30),
      Duration responseTimeout = const Duration(seconds: 60),
      bool adjustTiming = true,
      int intervalMs = 1200,
      EnumServerResponseType resType = EnumServerResponseType.json,
      String? charset,
      bool Function(String url, ServerResponse res, Object? error)? retryIf,
      int? maxRetries,
      Duration? baseDelay,
      Duration? maxJitter,
      CancelToken? cancelToken}) async {
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
            badCertificateCallback: badCertificateCallback,
            connectionTimeout: connectionTimeout,
            responseTimeout: responseTimeout,
            adjustTiming: adjustTiming,
            intervalMs: intervalMs,
            resType: resType,
            retryIf: retryIf,
            maxRetries: maxRetries,
            baseDelay: baseDelay,
            maxJitter: maxJitter,
            cancelToken: cancelToken);
      case EnumPostEncodeType.json:
        if (charset == null) {
          headers['Content-Type'] = 'application/json; charset=utf-8';
        } else if (charset == "") {
          headers['Content-Type'] = 'application/json';
        } else {
          headers['Content-Type'] = 'application/json; charset=$charset';
        }
        return customPost(url, jsonEncode(body), headers,
            badCertificateCallback: badCertificateCallback,
            connectionTimeout: connectionTimeout,
            responseTimeout: responseTimeout,
            adjustTiming: adjustTiming,
            intervalMs: intervalMs,
            resType: resType,
            retryIf: retryIf,
            maxRetries: maxRetries,
            baseDelay: baseDelay,
            maxJitter: maxJitter,
            cancelToken: cancelToken);
    }
  }

  /// (en) Build the https and POST it.
  /// This is a more customizable version, if you want a quicker experience
  /// you can use post function instead.
  /// When "200 <= statusCode <= 299", this method returns an object with
  /// EnumServerResponseStatus.success when communication was successful.
  /// In addition, for 401, it marks　EnumServerResponseStatus.signInRequired,
  /// for all other errors, whether the error is in the 400 or 500 range,
  /// it marks EnumServerResponseStatus.serverError,
  /// a communication timeout is marked as EnumServerResponseStatus.timeout,
  /// and other unknown errors are marked as EnumServerResponseStatus.otherError.
  /// A request cancelled via [cancelToken] is marked as
  /// EnumServerResponseStatus.cancelled.
  ///
  /// (ja) Httpsを構築してPOSTします。
  /// これはカスタマイズ性を高めたバージョンで、簡単に利用したい場合は代わりにpostが使えます。
  /// このメソッドは「200 <= statusCode <= 299」の時、
  /// EnumServerResponseStatus.successを持つ通信成功時のオブジェクトを返します。
  /// また、401ではEnumServerResponseStatus.signInRequiredを、
  /// それ以外の場合は400番台でも500番台でもEnumServerResponseStatus.serverErrorを、
  /// 通信時のタイムアウトはEnumServerResponseStatus.timeoutを、
  /// その他の未知のエラーはEnumServerResponseStatus.otherErrorとしてマークします。
  /// [cancelToken]によりキャンセルされた場合はEnumServerResponseStatus.cancelledを返します。
  ///
  /// * [url] : The URL to post to. Only https is permitted;
  /// anything else will return an error response.
  /// * [body] : Map&lt;String, dynamic&gt;, Json encoded string, or List&lt;int&gt;.
  /// * [headers] : HTTP headers.
  /// * [encoding] : The data encoding.
  /// * [badCertificateCallback] : Returns true if you are using a local server
  /// that uses a self-signed certificate.
  /// * [connectionTimeout] : The connection timeout.
  /// * [responseTimeout] : The response timeout.
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
  /// * [cancelToken] : Optional token used to cancel this request.
  static Future<ServerResponse> customPost(
      String url, Object? body, Map<String, String> headers,
      {Encoding? encoding,
      bool Function(X509Certificate cert, String host, int port)?
          badCertificateCallback,
      Duration connectionTimeout = const Duration(seconds: 30),
      Duration responseTimeout = const Duration(seconds: 60),
      bool adjustTiming = true,
      int intervalMs = 1200,
      EnumServerResponseType resType = EnumServerResponseType.json,
      bool Function(String url, ServerResponse res, Object? error)? retryIf,
      int? maxRetries,
      Duration? baseDelay,
      Duration? maxJitter,
      CancelToken? cancelToken}) async {
    final String httpsURL = UtilCheckURL.validateHttpsUrl(url);
    return runPostWithRetry(
      validatedUrl: httpsURL,
      send: (token) async {
        final HttpClient httpClient = HttpClient();
        if (badCertificateCallback != null) {
          httpClient.badCertificateCallback =
              (X509Certificate cert, String host, int port) =>
                  badCertificateCallback(cert, host, port);
        }
        httpClient.connectionTimeout = connectionTimeout;
        final ioClient = IOClient(httpClient);
        token?.attachClient(ioClient);
        try {
          return await ioClient
              .post(Uri.parse(httpsURL),
                  headers: headers, body: body, encoding: encoding)
              .timeout(responseTimeout);
        } finally {
          token?.detachClient(ioClient);
          ioClient.close();
        }
      },
      resType: resType,
      adjustTiming: adjustTiming,
      intervalMs: intervalMs,
      retryIf: retryIf,
      maxRetries: maxRetries,
      baseDelay: baseDelay,
      maxJitter: maxJitter,
      isExtraTimeoutError: (e) => e is SocketException,
      cancelToken: cancelToken,
    );
  }

  /// (en) Build the https and POST a raw binary payload.
  /// Useful for sending a single binary (image, PDF, encrypted blob, etc.)
  /// with a custom Content-Type. The body is sent as-is without any encoding.
  /// Native-only version with self-signed certificate support.
  ///
  /// (ja) Httpsを構築し、生のバイナリペイロードをPOSTします。
  /// 画像・PDF・暗号化済みデータなど、単一のバイナリを任意のContent-Typeで
  /// 送信する場合に使用します。Native専用で、自己署名証明書をサポートします。
  ///
  /// * [url] : The URL to post to. Only https is permitted;
  /// anything else will return an error response.
  /// * [bytes] : The binary payload to send.
  /// * [contentType] : The Content-Type header value.
  /// Defaults to "application/octet-stream".
  /// * [jwt] : The jwt. It is inserted into the Authorization header.
  /// * [badCertificateCallback] : Returns true if you are using a local server
  /// that uses a self-signed certificate.
  /// * [connectionTimeout] : The connection timeout.
  /// * [responseTimeout] : The response timeout.
  /// * [adjustTiming] : Specify true to automatically adjust the timing.
  /// * [intervalMs] : The minimum interval between calls.
  /// * [resType] : Formatting the return value from the server.
  /// * [retryIf] : Per-call retry condition.
  /// * [maxRetries] : Per-call override for RetryConfig.maxRetries.
  /// * [baseDelay] : Per-call override for RetryConfig.baseDelay.
  /// * [maxJitter] : Per-call override for RetryConfig.maxJitter.
  /// * [cancelToken] : Optional token used to cancel this request.
  static Future<ServerResponse> postBytes(String url, Uint8List bytes,
      {String contentType = 'application/octet-stream',
      String? jwt,
      bool Function(X509Certificate cert, String host, int port)?
          badCertificateCallback,
      Duration connectionTimeout = const Duration(seconds: 30),
      Duration responseTimeout = const Duration(seconds: 60),
      bool adjustTiming = true,
      int intervalMs = 1200,
      EnumServerResponseType resType = EnumServerResponseType.json,
      bool Function(String url, ServerResponse res, Object? error)? retryIf,
      int? maxRetries,
      Duration? baseDelay,
      Duration? maxJitter,
      CancelToken? cancelToken}) async {
    final Map<String, String> headers = {'Content-Type': contentType};
    if (jwt != null) {
      headers['Authorization'] = 'Bearer $jwt';
    }
    return customPost(url, bytes, headers,
        badCertificateCallback: badCertificateCallback,
        connectionTimeout: connectionTimeout,
        responseTimeout: responseTimeout,
        adjustTiming: adjustTiming,
        intervalMs: intervalMs,
        resType: resType,
        retryIf: retryIf,
        maxRetries: maxRetries,
        baseDelay: baseDelay,
        maxJitter: maxJitter,
        cancelToken: cancelToken);
  }

  /// (en) Build the https and POST as multipart/form-data.
  /// Useful for sending text fields together with one or more binary files
  /// in a single request. Native-only version with self-signed certificate
  /// support.
  ///
  /// (ja) Httpsを構築し、multipart/form-dataとしてPOSTします。
  /// テキストフィールドと1つ以上のバイナリファイルを同一リクエストで送信する
  /// 場合に使用します。Native専用で、自己署名証明書をサポートします。
  ///
  /// * [url] : The URL to post to. Only https is permitted;
  /// anything else will return an error response.
  /// * [fields] : Text fields. Sent as form fields.
  /// * [files] : File parts. Each entry must specify a field name and bytes.
  /// * [jwt] : The jwt. It is inserted into the Authorization header.
  /// * [badCertificateCallback] : Returns true if you are using a local server
  /// that uses a self-signed certificate.
  /// * [connectionTimeout] : The connection timeout.
  /// * [responseTimeout] : The response timeout.
  /// * [adjustTiming] : Specify true to automatically adjust the timing.
  /// * [intervalMs] : The minimum interval between calls.
  /// * [resType] : Formatting the return value from the server.
  /// * [retryIf] : Per-call retry condition.
  /// * [maxRetries] : Per-call override for RetryConfig.maxRetries.
  /// * [baseDelay] : Per-call override for RetryConfig.baseDelay.
  /// * [maxJitter] : Per-call override for RetryConfig.maxJitter.
  /// * [cancelToken] : Optional token used to cancel this request.
  static Future<ServerResponse> postMultipart(String url,
      {Map<String, String> fields = const {},
      List<MultipartFileSpec> files = const [],
      String? jwt,
      bool Function(X509Certificate cert, String host, int port)?
          badCertificateCallback,
      Duration connectionTimeout = const Duration(seconds: 30),
      Duration responseTimeout = const Duration(seconds: 60),
      bool adjustTiming = true,
      int intervalMs = 1200,
      EnumServerResponseType resType = EnumServerResponseType.json,
      bool Function(String url, ServerResponse res, Object? error)? retryIf,
      int? maxRetries,
      Duration? baseDelay,
      Duration? maxJitter,
      CancelToken? cancelToken}) async {
    final String httpsURL = UtilCheckURL.validateHttpsUrl(url);
    return runPostWithRetry(
      validatedUrl: httpsURL,
      send: (token) async {
        final HttpClient httpClient = HttpClient();
        if (badCertificateCallback != null) {
          httpClient.badCertificateCallback =
              (X509Certificate cert, String host, int port) =>
                  badCertificateCallback(cert, host, port);
        }
        httpClient.connectionTimeout = connectionTimeout;
        final ioClient = IOClient(httpClient);
        token?.attachClient(ioClient);
        try {
          final request = http.MultipartRequest('POST', Uri.parse(httpsURL));
          if (jwt != null) {
            request.headers['Authorization'] = 'Bearer $jwt';
          }
          request.fields.addAll(fields);
          for (final f in files) {
            request.files.add(http.MultipartFile.fromBytes(
              f.field,
              f.bytes,
              filename: f.filename,
              contentType: f.contentType != null
                  ? MediaType.parse(f.contentType!)
                  : null,
            ));
          }
          final streamed =
              await ioClient.send(request).timeout(responseTimeout);
          return await http.Response.fromStream(streamed);
        } finally {
          token?.detachClient(ioClient);
          ioClient.close();
        }
      },
      resType: resType,
      adjustTiming: adjustTiming,
      intervalMs: intervalMs,
      retryIf: retryIf,
      maxRetries: maxRetries,
      baseDelay: baseDelay,
      maxJitter: maxJitter,
      isExtraTimeoutError: (e) => e is SocketException,
      cancelToken: cancelToken,
    );
  }
}
