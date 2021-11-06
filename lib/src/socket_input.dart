import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import 'package:socket_io_client/socket_io_client.dart';

typedef InputReadyCallback = void Function(String id);

class LogInput {
  final String url;
  final sio.Socket socket;
  final InputReadyCallback onReady;

  bool _shouldForward = true;
  String _peer = '';

  String get peer => _peer;

  Stream<OutputEvent> get stream => _controller.stream;

  late StreamController<OutputEvent> _controller;

  LogInput({required this.url, required this.onReady})
      : socket = sio.io(url, OptionBuilder().enableForceNew().build()) {
    _controller = StreamController(
      onListen: () => _shouldForward = true,
      onPause: () => _shouldForward = false,
      onResume: () => _shouldForward = true,
      onCancel: () => _shouldForward = false,
    );

    socket.onConnect((_) {
      debugPrint('connected to url => $url, id => ${socket.id}');

      onReady(socket.id!);

      socket.on('msg', (data) {
        _peer = data[0];

        if (!_shouldForward) {
          debugPrint('will not forward stream');
          return;
        }

        OutputEvent event = _outputEvent(data[1]);
        _controller.add(event);
      });

      socket.onError((error) => debugPrint('error => $error'));

      socket.onConnectError((error) => debugPrint('error => $error'));

      socket.onConnectTimeout((error) => debugPrint('error => $error'));

      socket.onDisconnect((reason) =>
          debugPrint('disconnected from url => $url, reason => $reason'));
    });
  }

  void close() {
    socket.disconnect();
    socket.dispose();
  }

  OutputEvent _outputEvent(String msg) {
    Map<String, dynamic> obj = json.decode(msg);
    Level level = _level(obj['level']);
    List<dynamic> lines = obj['lines'];
    return OutputEvent(level, lines.map((e) => e as String).toList());
  }

  Level _level(String s) {
    s = s.toLowerCase();
    if (s.contains('verbose')) {
      return Level.verbose;
    } else if (s.contains('debug')) {
      return Level.debug;
    } else if (s.contains('info')) {
      return Level.info;
    } else if (s.contains('warning')) {
      return Level.warning;
    } else if (s.contains('error')) {
      return Level.error;
    } else if (s.contains('wtf')) {
      return Level.wtf;
    } else {
      return Level.nothing;
    }
  }
}
