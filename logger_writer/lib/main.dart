import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_socket_logger/flutter_socket_logger.dart';
import 'package:logger/logger.dart';

const String serverUrl = 'https://127.0.0.1';
final Logger localLogger = Logger();

Logger logger = localLogger;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Logger Writer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: '日志发送'),
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
  SocketOutput? _output;
  String? _peer;
  Timer? _timer;
  String _msg = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('请输入目标loggerId'),
              const SizedBox(height: 20),
              SizedBox(
                width: 400,
                child: TextField(
                  onChanged: (str) {
                    _peer = str;
                  },
                  decoration: const InputDecoration(
                    labelText: "loggerId",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              _msg != ''
                  ? Text(
                      _msg,
                      style: const TextStyle(color: Colors.red),
                    )
                  : const SizedBox(width: 0, height: 0),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () {
                    if (_output != null) {
                      _teardown();
                    } else {
                      if (_peer == null) {
                        setState(() {
                          _msg = 'please set a valid peer first';
                        });
                        return;
                      }
                      _setup();
                    }

                    setState(() {
                      _msg = '';
                    });
                  },
                  child: _output != null
                      ? const Text('stop')
                      : const Text('start'))
            ],
          ),
        ));
  }

  void _setup() {
    int i = 0;
    _output = SocketOutput(
        url: serverUrl,
        peer: _peer!,
        onBind: (ok) {
          if (!ok) {
            _teardown();
            setState(() {
              _msg = 'bind to peer failed';
            });
          }
        });

    logger = Logger(output: _output, filter: ProductFilter());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      logger.d('你好，flutter logger!!! ${++i} ' * 20);
    });
  }

  void _teardown() {
    _timer?.cancel();
    _output = null;
    _timer = null;
    logger = localLogger;
  }
}
