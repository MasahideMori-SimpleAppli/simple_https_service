# simple_https_service

(en)Japanese ver is [here](https://github.com/MasahideMori-SimpleAppli/simple_https_service/blob/main/README_JA.md).  
(ja)この解説の日本語版は[ここ](https://github.com/MasahideMori-SimpleAppli/simple_https_service/blob/main/README_JA.md)にあります。

## Overview
This package provides simple HTTPS POST communication for Flutter applications.  
It includes timing control to respect server-side rate limits, automatic retry with exponential backoff, and a unified response object that categorizes server responses into easy-to-handle statuses.

Two implementations are provided:
- `HttpsService`: Works on both web and native platforms.
- `HttpsServiceForNative`: Native-only, with support for self-signed certificates via `badCertificateCallback`.

## Features
- HTTPS-only POST (http URLs are rejected with an exception)
- `jwt` parameter to automatically set the `Authorization: Bearer` header
- Unified `ServerResponse` with five statuses: `success`, `timeout`, `serverError`, `otherError`, `signInRequired`
- Response body as JSON, raw bytes, or UTF-8 text
- `TimingManager`: Singleton that enforces a minimum interval between requests
- `RetryConfig`: Singleton for automatic retry with exponential backoff and configurable jitter

## Usage

### Basic POST

```dart
import 'package:simple_https_service/simple_https_service.dart';

final res = await HttpsService.post(
  'https://api.example.com/data',
  {'key': 'value'},
  EnumPostEncodeType.json,
);

switch (res.resultStatus) {
  case EnumServerResponseStatus.success:
    print(res.resBody);
  case EnumServerResponseStatus.timeout:
    print('timeout: ${res.errorDetail}');
  case EnumServerResponseStatus.serverError:
    print('server error: ${res.errorDetail}');
  case EnumServerResponseStatus.signInRequired:
    print('sign-in required');
  case EnumServerResponseStatus.otherError:
    print('error: ${res.errorDetail}');
}
```

### Custom POST (advanced headers)

```dart
import 'package:simple_https_service/simple_https_service.dart';

final res = await HttpsService.customPost(
  'https://api.example.com/data',
  '{"key":"value"}',
  {'Content-Type': 'application/json; charset=utf-8'},
  timeout: const Duration(seconds: 10),
);

switch (res.resultStatus) {
  case EnumServerResponseStatus.success:
    print(res.resBody);
  default:
    print('error: ${res.errorDetail}');
}
```

### POST with JWT authentication

```dart
import 'package:simple_https_service/simple_https_service.dart';

final res = await HttpsService.post(
  'https://api.example.com/data',
  {'key': 'value'},
  EnumPostEncodeType.json,
  jwt: 'your_access_token',
);

switch (res.resultStatus) {
  case EnumServerResponseStatus.success:
    print(res.resBody);
  case EnumServerResponseStatus.signInRequired:
    print('token expired or invalid');
  default:
    print('error: ${res.errorDetail}');
}
```

### Native-only POST with self-signed certificate

```dart
import 'package:simple_https_service/simple_https_service.dart';

final res = await HttpsServiceForNative.post(
  'https://192.168.1.1/api',
  {'key': 'value'},
  EnumPostEncodeType.json,
  badCertificateCallback: (cert, host, port) => true,
  connectionTimeout: const Duration(seconds: 5),
  responseTimeout: const Duration(seconds: 30),
);

switch (res.resultStatus) {
  case EnumServerResponseStatus.success:
    print(res.resBody);
  case EnumServerResponseStatus.timeout:
    print('timeout: ${res.errorDetail}');
  default:
    print('error: ${res.errorDetail}');
}
```

### Timing control

By default, all requests automatically pass through `TimingManager` (`adjustTiming` defaults to `true`).
Each request waits until `intervalMs` milliseconds have elapsed since the previous request, preventing server-side rate limit errors.

```dart
// Default: automatically maintains a 1200ms minimum interval between requests.
await HttpsService.post(url, body, type);

// Disable timing control for a specific call.
await HttpsService.post(url, body, type, adjustTiming: false);

// Use a custom interval (milliseconds).
await HttpsService.post(url, body, type, intervalMs: 500);
```

### Automatic retry

```dart
// Global configuration (set once at app startup)
RetryConfig()
  ..maxRetries = 3
  ..baseDelay = const Duration(seconds: 1)
  ..maxJitter = const Duration(milliseconds: 500)
  ..defaultCondition = (url, res, error) {
    if (url.endsWith('/revoke')) return false;
    return error.toString().contains('Failed to fetch');
  };

// Per-call override
final res = await HttpsService.post(
  'https://api.example.com/data',
  body,
  EnumPostEncodeType.json,
  retryIf: (url, res, error) => res.resultStatus == EnumServerResponseStatus.timeout,
  maxRetries: 2,
);
```

The retry delay follows exponential backoff with optional jitter:  
`delay = baseDelay * 2^(n-1) + Random(0, maxJitter)`

## Support
Basically no support.  
If you have any problem please open an issue on Github.  
This package is low priority, but may be fixed.

## About version control
The C part will be changed at the time of version upgrade.  
However, versions less than 1.0.0 may change the file structure regardless of the following rules.  
- Changes such as adding variables, structure change that cause problems when reading previous files.
    - C.X.X
- Adding methods, etc.
    - X.C.X
- Minor changes and bug fixes.
    - X.X.C

## License
Copyright 2026 Masahide Mori

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Trademarks

- "Dart" and "Flutter" are trademarks of Google LLC.  
  *This package is not developed or endorsed by Google LLC.*
