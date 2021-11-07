import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter_socket_logger/flutter_socket_logger.dart';
import 'package:logger/logger.dart';

const String serverUrl = 'https://127.0.0.1';
Logger logger =
    Logger(output: MultiOutput([ConsoleOutput()])); //default log to local

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Logger',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Logger Example Homepage'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late LogInput _logInput;
  String _loggerId = '';

  void _initLogInput(String url) {
    _logInput = LogInput(
        url: url,
        onReady: (id) {
          setState(() {
            _loggerId = id;
          });

          logger.close();
          var logOutput = SocketOutput(url: url, peer: id);
          logger = Logger(
              output: MultiOutput([logOutput])); //switch logging to remote
        });
  }

  void _startLogStream(int milliseconds) {
    int c = 0;
    Timer.periodic(Duration(milliseconds: milliseconds), (t) {
      ++c;
      logger.w('ping 中文！$c ' * 100);
    });
  }

  @override
  void initState() {
    super.initState();

    _initLogInput(serverUrl);
    _startLogStream(1000);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        body: LogConsole(
      loggerId: _loggerId,
      logStream: _logInput.stream,
      dark: true,
    ));
  }

  @override
  void dispose() {
    _logInput.close();
    super.dispose();
  }
}
