import 'package:flutter/material.dart';

enum States { text, bracket, code }

class AnsiParser {
  final bool dark;

  List<TextSpan> spans = [];

  AnsiParser(this.dark);

  Color? _foreground;
  Color? _background;

  void parse(String s) {
    var state = States.text;
    late StringBuffer buffer;
    var text = StringBuffer();
    var code = 0;
    late List<int> codes;

    for (var i = 0, n = s.length; i < n; i++) {
      var c = s[i];

      switch (state) {
        case States.text:
          if (c == '\u001b') {
            state = States.bracket;
            buffer = StringBuffer(c);
            code = 0;
            codes = [];
          } else {
            text.write(c);
          }
          break;

        case States.bracket:
          buffer.write(c);
          if (c == '[') {
            state = States.code;
          } else {
            state = States.text;
            text.write(buffer);
          }
          break;

        case States.code:
          buffer.write(c);
          var codeUnit = c.codeUnitAt(0);
          if (codeUnit >= 48 && codeUnit <= 57) {
            code = code * 10 + codeUnit - 48;
            continue;
          } else if (c == ';') {
            codes.add(code);
            code = 0;
            continue;
          } else {
            if (text.isNotEmpty) {
              spans.add(_createSpan(text.toString()));
              text.clear();
            }
            state = States.text;
            if (c == 'm') {
              codes.add(code);
              _handleCodes(codes);
            } else {
              text.write(buffer);
            }
          }

          break;
      }
    }

    spans.add(_createSpan(text.toString()));
  }

  void _handleCodes(List<int> codes) {
    if (codes.isEmpty) {
      codes.add(0);
    }

    switch (codes[0]) {
      case 0:
        _foreground = _getColor(0, true);
        _background = _getColor(0, false);
        break;
      case 38:
        _foreground = _getColor(codes[2], true);
        break;
      case 39:
        _foreground = _getColor(0, true);
        break;
      case 48:
        _background = _getColor(codes[2], false);
        break;
      case 49:
        _background = _getColor(0, false);
    }
  }

  Color _getColor(int colorCode, bool foreground) {
    switch (colorCode) {
      case 12:
        return dark ? Colors.lightBlue.shade300 : Colors.indigo.shade700;
      case 208:
        return dark ? Colors.orange.shade300 : Colors.orange.shade700;
      case 196:
        return dark ? Colors.red.shade300 : Colors.red.shade700;
      case 199:
        return dark ? Colors.pink.shade300 : Colors.pink.shade700;
      default:
        return foreground ? Colors.black : Colors.transparent;
    }
  }

  TextSpan _createSpan(String text) {
    return TextSpan(
        text: text,
        style: TextStyle(
            color: _foreground,
            backgroundColor: _background,
            fontFamily: 'JetBrains Mono'));
  }
}
