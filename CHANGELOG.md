## 1.0.0 (2026-05-02)

* Initial release.
* `HttpsService`: HTTPS POST for web and native platforms.
* `HttpsServiceForNative`: HTTPS POST for native platforms with self-signed certificate support.
* `TimingManager`: Singleton for controlling request intervals.
* `RetryConfig`: Singleton for configuring automatic retry with exponential backoff and jitter.
* `ServerResponse`: Unified response object with categorized status.
* `EnumServerResponseStatus`: Response status enum (success, timeout, serverError, otherError, signInRequired).
* `EnumServerResponseType`: Response body format enum (json, byte, text).
* `EnumPostEncodeType`: POST encoding type enum (urlEncoded, json).
* `UtilCheckURL`: Utility for HTTPS URL validation.
* `UtilServerResponse`: Factory utility for creating `ServerResponse` objects.
