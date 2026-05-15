import 'dart:async';
import 'package:http/http.dart' as http;

/// (en) A token that lets the caller cancel one or more in-flight requests
/// issued through [HttpsService] or [HttpsServiceForNative].
///
/// The same token can be passed to multiple requests; calling [cancel]
/// aborts all of them at once. A token is single-shot: once cancelled it
/// stays cancelled, and any subsequent request that receives the token
/// returns immediately with [EnumServerResponseStatus.cancelled].
///
/// Cancellation works at three points:
/// 1. While waiting for `TimingManager` to release the next slot.
/// 2. While waiting for the exponential backoff delay between retries.
/// 3. During the HTTP send itself. The token holds a reference to the
///    active [http.Client] for each in-flight request and calls
///    [http.Client.close] on cancel. How that abort propagates to the
///    network layer is delegated to the `http` package and the platform;
///    this class does not depend on any particular underlying transport.
///
/// (ja) [HttpsService]や[HttpsServiceForNative]経由で送信中のリクエストを
/// 呼び出し側からキャンセルするためのトークンです。
///
/// 同じトークンを複数のリクエストに渡すことができ、[cancel]を1回呼ぶと
/// それら全てを同時に中断します。トークンは一度きりの動作で、キャンセル後は
/// 状態が保持され、その後そのトークンを受け取ったリクエストは即座に
/// [EnumServerResponseStatus.cancelled]で返ります。
///
/// キャンセルは以下3点で割り込みます：
/// 1. `TimingManager`の次スロット待機中。
/// 2. リトライ間の指数バックオフ待機中。
/// 3. HTTP送信中。トークンは各リクエストの[http.Client]を保持し、
///    キャンセル時に[http.Client.close]を呼びます。実際にネットワーク層
///    でどのように中断が伝播するかは`http`パッケージとプラットフォームの
///    実装に委ねられており、このクラスは特定の通信方式に依存しません。
///
/// Author Masahide Mori
///
/// First edition creation date 2026-05-15 21:00:00
class CancelToken {
  final Completer<void> _completer = Completer<void>();
  final Set<http.Client> _attachedClients = {};

  /// (en) Whether [cancel] has been called.
  ///
  /// (ja) [cancel]が既に呼ばれたかどうか。
  bool get isCancelled => _completer.isCompleted;

  /// (en) Completes when [cancel] is called. Useful for racing against
  /// other futures via [Future.any].
  ///
  /// (ja) [cancel]が呼ばれた時に完了するFuture。[Future.any]で他のFutureと
  /// レースさせる用途に使えます。
  Future<void> get whenCancelled => _completer.future;

  /// (en) Cancels every request currently attached to this token and
  /// prevents future requests that receive this token from being sent.
  /// Calling cancel more than once is a no-op.
  ///
  /// (ja) このトークンに紐づく全リクエストを中断し、以降このトークンを
  /// 受け取るリクエストの送信を抑止します。複数回呼んでも無効動作です。
  void cancel() {
    if (_completer.isCompleted) return;
    _completer.complete();
    final clients = List<http.Client>.from(_attachedClients);
    for (final c in clients) {
      try {
        c.close();
      } catch (_) {
        // Closing an already-finished client may throw on some platforms;
        // we intentionally swallow it because cancel() must be best-effort.
      }
    }
    _attachedClients.clear();
  }

  /// (en) Internal: register a client so it is closed when [cancel] fires.
  /// If the token is already cancelled, the client is closed immediately.
  ///
  /// (ja) 内部用：[cancel]発火時にcloseされるようクライアントを登録します。
  /// 既にキャンセル済みの場合は、その場で即closeします。
  void attachClient(http.Client client) {
    if (_completer.isCompleted) {
      try {
        client.close();
      } catch (_) {}
      return;
    }
    _attachedClients.add(client);
  }

  /// (en) Internal: detach a client after the request finishes normally.
  ///
  /// (ja) 内部用：リクエストが正常終了した後にクライアントを外します。
  void detachClient(http.Client client) {
    _attachedClients.remove(client);
  }
}
