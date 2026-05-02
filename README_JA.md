# simple_https_service

## 概要
このパッケージは、Flutterアプリケーション向けにシンプルなHTTPS POST通信を提供します。  
サーバー側のレート制限に対応するタイミング制御、指数バックオフによる自動リトライ、そしてサーバー応答を扱いやすいステータスに分類した統一レスポンスオブジェクトを備えています。

2つの実装が用意されています：
- `HttpsService`: WebとNativeの両プラットフォームで動作します。
- `HttpsServiceForNative`: Native専用で、`badCertificateCallback`による自己署名証明書のサポートがあります。

## 機能
- HTTPSのみのPOST（httpのURLは例外をスローして拒否）
- `jwt` パラメータで `Authorization: Bearer` ヘッダーを自動付加
- 5つのステータスを持つ統一 `ServerResponse`: `success`、`timeout`、`serverError`、`otherError`、`signInRequired`
- レスポンスボディをJSON・バイト列・UTF-8テキストとして取得可能
- `TimingManager`: リクエスト間の最小間隔を強制するシングルトン
- `RetryConfig`: 指数バックオフと設定可能なジッターによる自動リトライのシングルトン

## 使い方

### 基本的なPOST

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
    print('タイムアウト: ${res.errorDetail}');
  case EnumServerResponseStatus.serverError:
    print('サーバーエラー: ${res.errorDetail}');
  case EnumServerResponseStatus.signInRequired:
    print('サインインが必要です');
  case EnumServerResponseStatus.otherError:
    print('エラー: ${res.errorDetail}');
}
```

### カスタムPOST（詳細なヘッダー指定）

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
    print('エラー: ${res.errorDetail}');
}
```

### JWT認証付きPOST

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
    print('トークンの期限切れまたは無効');
  default:
    print('エラー: ${res.errorDetail}');
}
```

### 自己署名証明書を使ったNative専用POST

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
    print('タイムアウト: ${res.errorDetail}');
  default:
    print('エラー: ${res.errorDetail}');
}
```

### タイミング制御

デフォルトでは、全リクエストが自動的に `TimingManager` を経由します（`adjustTiming` のデフォルトは `true`）。
前回のリクエストから `intervalMs` ミリ秒が経過するまで次のリクエストを待機させることで、サーバー側のレート制限エラーを防ぎます。

```dart
// デフォルト：自動で最低1200ms間隔を維持します。
await HttpsService.post(url, body, type);

// 特定の呼び出しでタイミング制御を無効化する場合。
await HttpsService.post(url, body, type, adjustTiming: false);

// 間隔をカスタマイズする場合（ミリ秒単位）。
await HttpsService.post(url, body, type, intervalMs: 500);
```

### 自動リトライ

```dart
// グローバル設定（アプリ起動時に一度設定）
RetryConfig()
  ..maxRetries = 3
  ..baseDelay = const Duration(seconds: 1)
  ..maxJitter = const Duration(milliseconds: 500)
  ..defaultCondition = (url, res, error) {
    if (url.endsWith('/revoke')) return false;
    return error.toString().contains('Failed to fetch');
  };

// 呼び出し側での個別オーバーライド
final res = await HttpsService.post(
  'https://api.example.com/data',
  body,
  EnumPostEncodeType.json,
  retryIf: (url, res, error) => res.resultStatus == EnumServerResponseStatus.timeout,
  maxRetries: 2,
);
```

リトライ間隔は指数バックオフにオプションのジッターを加えた方式です：  
`delay = baseDelay * 2^(n-1) + Random(0, maxJitter)`

## サポート
基本的にサポートはありません。  
もし問題がある場合はGithubのissueを開いてください。  
このパッケージは優先度が低いですが、修正される可能性があります。

## バージョン管理について
それぞれ、Cの部分が変更されます。  
ただし、バージョン1.0.0未満は以下のルールに関係無くファイル構造が変化する場合があります。  
- 変数の追加など、以前のファイルの読み込み時に問題が起こったり、ファイルの構造が変わるような変更
  - C.X.X
- メソッドの追加など
  - X.C.X
- 軽微な変更やバグ修正
  - X.X.C

## ライセンス
このソフトウェアはApache-2.0ライセンスの元配布されます。LICENSEファイルの内容をご覧ください。

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

- "Dart" および "Flutter" は Google LLC の商標です。  
  *このパッケージは Google LLC によって開発・推奨されたものではありません。*
