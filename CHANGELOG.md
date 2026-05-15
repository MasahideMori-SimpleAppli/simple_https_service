## 1.1.0 (2026-05-15)

* Added `postBytes` for sending raw binary payloads with a custom Content-Type
  (defaults to `application/octet-stream`).
* Added `postMultipart` for sending `multipart/form-data` with text fields and
  binary files. Only byte input is supported via the new `MultipartFileSpec`
  class to keep retries safe and the API simple.
* `MultipartFileSpec` supports an optional `contentType` (e.g. `"image/png"`)
  so each part can carry its own MIME type. When omitted, the multipart
  default `application/octet-stream` is used.
* Both new methods are available on `HttpsService` and `HttpsServiceForNative`
  and share the same timing/retry/response handling as `post` / `customPost`.
* Added `http_parser` (already a transitive dependency of `http`) to
  dependencies so per-part `contentType` strings can be parsed via
  `MediaType.parse`.
* Internal: extracted the retry + timing + response formatting loop into a
  private helper (`lib/src/network/post_runner.dart`) to remove duplication
  between `HttpsService` and `HttpsServiceForNative`. No behavior change for
  existing methods.

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
