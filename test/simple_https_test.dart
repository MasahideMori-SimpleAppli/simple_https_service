import 'package:flutter_test/flutter_test.dart';
import 'package:simple_https_service/simple_https_service.dart';

void main() {
  group('UtilCheckURL', () {
    test('validateHttpsUrl returns url when scheme is https', () {
      const url = 'https://example.com/api';
      expect(UtilCheckURL.validateHttpsUrl(url), url);
    });

    test('validateHttpsUrl throws when scheme is http', () {
      expect(
        () => UtilCheckURL.validateHttpsUrl('http://example.com/api'),
        throwsException,
      );
    });

    test('validateHttpsUrl throws when scheme is missing', () {
      expect(
        () => UtilCheckURL.validateHttpsUrl('example.com/api'),
        throwsException,
      );
    });
  });

  group('TimingManager', () {
    test('is singleton', () {
      final a = TimingManager();
      final b = TimingManager();
      expect(identical(a, b), isTrue);
    });
  });

  group('EnumPostEncodeType', () {
    test('has urlEncoded and json values', () {
      expect(
          EnumPostEncodeType.values,
          containsAll(
              [EnumPostEncodeType.urlEncoded, EnumPostEncodeType.json]));
    });
  });

  group('EnumServerResponseStatus', () {
    test('has all expected values', () {
      expect(
        EnumServerResponseStatus.values,
        containsAll([
          EnumServerResponseStatus.success,
          EnumServerResponseStatus.timeout,
          EnumServerResponseStatus.serverError,
          EnumServerResponseStatus.otherError,
          EnumServerResponseStatus.signInRequired,
        ]),
      );
    });
  });

  group('UtilServerResponse', () {
    test('timeout creates response with timeout status', () {
      final res = UtilServerResponse.timeout(Exception('timed out'));
      expect(res.resultStatus, EnumServerResponseStatus.timeout);
      expect(res.response, isNull);
    });

    test('otherError creates response with otherError status', () {
      final res = UtilServerResponse.otherError(Exception('unknown'));
      expect(res.resultStatus, EnumServerResponseStatus.otherError);
      expect(res.response, isNull);
    });

    test('signInRequired without response creates unauthenticated response',
        () {
      final res = UtilServerResponse.signInRequired();
      expect(res.resultStatus, EnumServerResponseStatus.signInRequired);
      expect(res.errorDetail, 'Unauthenticated.');
    });
  });

  group('RetryConfig', () {
    setUp(() {
      RetryConfig().maxRetries = 3;
      RetryConfig().baseDelay = const Duration(seconds: 1);
      RetryConfig().maxJitter = const Duration(milliseconds: 500);
      RetryConfig().defaultCondition = null;
    });

    test('is singleton', () {
      final a = RetryConfig();
      final b = RetryConfig();
      expect(identical(a, b), isTrue);
    });

    test('has correct defaults after reset', () {
      expect(RetryConfig().maxRetries, 3);
      expect(RetryConfig().baseDelay, const Duration(seconds: 1));
      expect(RetryConfig().maxJitter, const Duration(milliseconds: 500));
      expect(RetryConfig().defaultCondition, isNull);
    });

    test('defaultCondition can be set and cleared', () {
      RetryConfig().defaultCondition = (url, res, error) => true;
      expect(RetryConfig().defaultCondition, isNotNull);

      RetryConfig().defaultCondition = null;
      expect(RetryConfig().defaultCondition, isNull);
    });

    test('defaultCondition receives url, response and error', () {
      String? capturedUrl;
      ServerResponse? capturedRes;
      Object? capturedError;

      RetryConfig().defaultCondition = (url, res, error) {
        capturedUrl = url;
        capturedRes = res;
        capturedError = error;
        return false;
      };

      const testUrl = 'https://example.com';
      final testRes = UtilServerResponse.otherError(Exception('test'));
      final testError = Exception('test');

      RetryConfig().defaultCondition!(testUrl, testRes, testError);

      expect(capturedUrl, testUrl);
      expect(capturedRes, testRes);
      expect(capturedError, testError);
    });

    test('url-based routing in defaultCondition', () {
      RetryConfig().defaultCondition = (url, res, error) {
        if (url.endsWith('/revoke')) return false;
        return error.toString().contains('Failed to fetch');
      };

      final res = UtilServerResponse.otherError(Exception('Failed to fetch'));
      final err = Exception('Failed to fetch');

      expect(
          RetryConfig().defaultCondition!(
              'https://api.example.com/data', res, err),
          isTrue);
      expect(
          RetryConfig().defaultCondition!(
              'https://api.example.com/revoke', res, err),
          isFalse);
    });
  });
}
