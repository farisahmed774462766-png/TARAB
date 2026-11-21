import 'dart:async';
import 'dart:convert';
import 'dart:io';

class TarabSocketService {
  WebSocket? _socket;
  final StreamController> _eventsController =
      StreamController>.broadcast();

  Stream> get events => _eventsController.stream;

  bool get isConnected => _socket != null;

  Future<void> connect(String url) async {
    if (_socket != null) return;

    final socket = await WebSocket.connect(url);
    _socket = socket;

    socket.listen(
      (dynamic rawMessage) {
        if (rawMessage is String) {
          try {
            final decoded = jsonDecode(rawMessage);
            if (decoded is Map<String, dynamic>) {
              _eventsController.add(decoded);
            }
          } catch (_) {
            _eventsController.add({
              'type': 'RAW_MESSAGE',
              'data': rawMessage,
            });
          }
        }
      },
      onError: (Object error) {
        _eventsController.add({
          'type': 'SOCKET_ERROR',
          'message': error.toString(),
        });
      },
      onDone: () {
        _socket = null;
        _eventsController.add({
          'type': 'SOCKET_CLOSED',
        });
      },
      cancelOnError: false,
    );
  }

  void sendEvent(String type, Map<String, dynamic> payload) {
    final socket = _socket;
    if (socket == null) {
      throw StateError('غير متصل بخادم WebSocket حالياً');
    }

    socket.add(
      jsonEncode({
        'type': type,
        'payload': payload,
      }),
    );
  }

  void createTable({
    String? tableId,
    bool isPrivate = false,
    int entryFee = 1000,
  }) {
    sendEvent('CREATE_TABLE', {
      if (tableId != null) 'tableId': tableId,
      'isPrivate': isPrivate,
      'entryFee': entryFee,
    });
  }

  void joinTable({
    required String tableId,
    required String playerId,
    String? playerName,
    bool isBot = false,
  }) {
    sendEvent('JOIN_TABLE', {
      'tableId': tableId,
      'playerId': playerId,
      if (playerName != null) 'playerName': playerName,
      'isBot': isBot,
    });
  }

  void startRound({
    required String tableId,
    int cardsPerPlayer = 5,
  }) {
    sendEvent('START_ROUND', {
      'tableId': tableId,
      'cardsPerPlayer': cardsPerPlayer,
    });
  }

  void playCard({
    required String tableId,
    required String playerId,
    required String cardId,
  }) {
    sendEvent('PLAY_CARD', {
      'tableId': tableId,
      'playerId': playerId,
      'cardId': cardId,
    });
  }

  void applyReward({
    required String playerId,
    required int amount,
    String source = 'daily_checkin',
  }) {
    sendEvent('APPLY_REWARD', {
      'playerId': playerId,
      'amount': amount,
      'source': source,
    });
  }

  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _eventsController.close();
  }
}
