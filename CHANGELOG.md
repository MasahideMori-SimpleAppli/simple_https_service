## 2.0.0 (2026-05-15)

* Added `CancelToken`: a caller-driven cancellation token that can be shared
  across multiple in-flight requests. Calling `cancel()` aborts every
  request currently using the token by closing the underlying `http.Client`,
  and also interrupts any pending TimingManager wait or exponential-backoff
  delay. (How `Client.close()` aborts the in-flight request is delegated
  to the `http` package and the platform; this package does not depend on
  any particular underlying transport.)
* Added `EnumServerResponseStatus.cancelled` and
  `UtilServerResponse.cancelled()` so cancelled requests can be
  distinguished from real failures in UI / error reporting paths.
* All POST methods on `HttpsService` and `HttpsServiceForNative`
  (`post`, `customPost`, `postBytes`, `postMultipart`) now accept an
  optional `cancelToken` parameter.
* BREAKING: `EnumServerResponseStatus` gained a new value (`cancelled`).
  Any exhaustive `switch` on the enum will need an additional case.
* Internal: `HttpsService` no longer uses the `http.post()` / `http.send()`
  static helpers and instead manages an `http.Client` per attempt so it
  can be closed to abort an in-flight request. No behavior change for
  callers that do not use cancellation.

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
