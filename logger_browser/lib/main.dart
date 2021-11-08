import 'package:flutter/material.dart';

import 'package:flutter_socket_logger/flutter_socket_logger.dart';

const String serverUrl = 'https://127.0.0.1';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Logger Browser',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: '日志控制台'),
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
        });
  }

  @override
  void initState() {
    super.initState();

    _initLogInput(serverUrl);
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
