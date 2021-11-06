import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'package:socket_io_client/socket_io_client.dart' as sio;
import 'package:socket_io_client/socket_io_client.dart';

class SocketOutClient {
  final String url;
  final String peer;
  final sio.Socket socket;

  SocketOutClient({required this.url, required this.peer})
      : socket = sio.io(url, OptionBuilder().enableForceNew().build()) {
    socket.onConnect((_) {
      debugPrint('connected to url => $url, id => ${socket.id}');

      socket.emitWithAck('bind', peer, ack: (bool ok) {
        debugPrint('bind => [${socket.id} -> $peer] : $ok');
      });
    });

    socket.onError((error) => debugPrint('error => $error'));

    socket.onConnectError((error) => debugPrint('error => $error'));

    socket.onConnectTimeout((error) => debugPrint('error => $error'));

    socket.onDisconnect((reason) =>
        debugPrint('disconnected from url => $url, reason => $reason'));
  }

  void postMsg(String msg) async {
    if (!socket.connected) {
      debugPrint('sockect is not connected');
      return;
    }

    socket.emit('msg', msg);
  }

  void close() {
    socket.disconnect();
    socket.dispose();
  }
}

class SocketOutput extends LogOutput {
  final SocketOutClient _client;

  SocketOutput({required String url, required String peer})
      : _client = SocketOutClient(url: url, peer: peer);

  @override
  void output(OutputEvent event) {
    _client.postMsg(_encodeEvent(event));
  }

  @override
  void destroy() {
    _client.close();
  }

  String _encodeEvent(OutputEvent event) {
    Map<String, dynamic> obj = {};
    obj['level'] = '${event.level}';
    obj['lines'] = event.lines;

    return json.encode(obj);
  }
}
