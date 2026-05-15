/// (en) To simplify responses from the server,
/// This is an enum that classifies the response content into
/// six types:
/// successful processing, timeout(connection or response), server error,
/// other error, SignIn required, and cancelled by the caller.
///
/// (ja) サーバーからの応答を単純化するために、
/// 応答内容を処理成功、タイムアウト（通信または応答）、サーバーエラー、
/// その他のエラー、要signIn、呼び出し側によるキャンセルの６種類に分類するためのenumです。
///
/// Author Masahide Mori
///
/// First edition creation date 2024-10-29 17:34:13
enum EnumServerResponseStatus {
  success,
  timeout,
  serverError,
  otherError,
  signInRequired,
  cancelled,
}
