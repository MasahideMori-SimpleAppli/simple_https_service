import 'dart:typed_data';

/// (en) Specifies a single file part for multipart/form-data POST.
///
/// To keep the API simple and to guarantee that retries can re-send the
/// same payload, only byte input is supported. Streams and file paths are
/// intentionally not accepted.
///
/// (ja) multipart/form-data POSTにおける個々のファイルパートを表します。
///
/// シンプルさと、リトライ時に同じデータを再送できる安全性を担保するため、
/// 入力はバイト列のみをサポートします。Streamやファイルパスは
/// 意図的に受け付けません。
///
/// Author Masahide Mori
///
/// First edition creation date 2026-05-15 16:30:00
class MultipartFileSpec {
  /// (en) Form field name. Required.
  ///
  /// (ja) フォームのフィールド名。必須です。
  final String field;

  /// (en) File contents as bytes. Required.
  ///
  /// (ja) ファイルの本体バイト列。必須です。
  final Uint8List bytes;

  /// (en) Optional filename to expose to the server.
  ///
  /// (ja) サーバーに送信するファイル名（任意）です。
  final String? filename;

  /// (en) Optional MIME type for this part (e.g. "image/png",
  /// "application/pdf"). If null, the part will use the multipart default
  /// "application/octet-stream". The string is parsed at send time;
  /// malformed values will cause the request to fail with otherError.
  ///
  /// (ja) このパートのMIMEタイプ（例: "image/png"、"application/pdf"）。
  /// nullの場合、multipartの既定値である "application/octet-stream" が
  /// 使われます。文字列は送信時にパースされ、不正な値はotherErrorとして
  /// リクエストが失敗します。
  final String? contentType;

  /// * [field] : Form field name.
  /// * [bytes] : File contents as bytes.
  /// * [filename] : Optional filename.
  /// * [contentType] : Optional MIME type string (e.g. "image/png").
  const MultipartFileSpec({
    required this.field,
    required this.bytes,
    this.filename,
    this.contentType,
  });
}
