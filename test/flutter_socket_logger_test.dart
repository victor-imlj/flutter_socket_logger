import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_socket_logger/flutter_socket_logger.dart';
import 'package:logger/logger.dart';

const url = '127.0.0.1';
Logger logger = Logger();

void main() {
  test('pipe', () {
    late LogInput input;
    input = LogInput(
        url: url,
        onReady: (id) async {
          logger = Logger(output: SocketOutput(url: url, peer: id));
          logger.d('hello');
          await for (final event in input.stream) {
            debugPrint('$event');
          }
        });
  });
}
