import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'ansi_parser.dart';

class RenderedEvent {
  final int id;
  final Level level;
  final TextSpan span;
  final String lowerCaseText;

  RenderedEvent(this.id, this.level, this.span, this.lowerCaseText);
}

ListQueue<OutputEvent> _outputEventBuffer = ListQueue();

class LogConsole extends StatefulWidget {
  final bool dark;
  final bool showCloseButton;
  final int bufferSize;
  final Stream<OutputEvent> logStream;
  final String? loggerId;

  const LogConsole(
      {Key? key,
      this.dark = false,
      this.showCloseButton = false,
      this.loggerId,
      required this.logStream,
      this.bufferSize = 1000})
      : super(key: key);

  @override
  _LogConsoleState createState() => _LogConsoleState();
}

class _LogConsoleState extends State<LogConsole> {
  final ListQueue<RenderedEvent> _renderedBuffer = ListQueue();
  List<RenderedEvent> _filteredBuffer = [];

  final _scrollController = ScrollController();
  final _filterController = TextEditingController();

  Level _filterLevel = Level.verbose;
  double _logFontSize = 14;

  var _currentId = 0;
  bool _scrollListenerEnabled = true;
  bool _followBottom = true;
  bool _showQROverlay = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (!_scrollListenerEnabled) return;
      var scrolledToBottom = _scrollController.offset >=
          _scrollController.position.maxScrollExtent;
      setState(() {
        _followBottom = scrolledToBottom;
      });
    });

    widget.logStream.listen((event) {
      if (_renderedBuffer.length == widget.bufferSize) {
        _renderedBuffer.removeFirst();
      }

      _renderedBuffer.add(_renderEvent(event));
      _refreshFilter();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _renderedBuffer.clear();
    for (var event in _outputEventBuffer) {
      _renderedBuffer.add(_renderEvent(event));
    }
    // _refreshFilter();
  }

  void _refreshFilter() {
    var newFilteredBuffer = _renderedBuffer.where((it) {
      var logLevelMatches = it.level.index >= _filterLevel.index;
      if (!logLevelMatches) {
        return false;
      } else if (_filterController.text.isNotEmpty) {
        var filterText = _filterController.text.toLowerCase();
        return it.lowerCaseText.contains(filterText);
      } else {
        return true;
      }
    }).toList();
    setState(() {
      _filteredBuffer = newFilteredBuffer;
    });

    if (_followBottom) {
      Future.delayed(Duration.zero, _scrollToBottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: widget.dark
          ? ThemeData(brightness: Brightness.dark)
          : ThemeData(brightness: Brightness.light),
      home: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTopBar(),
              Expanded(
                child: _buildLogContent(),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
        floatingActionButton: AnimatedOpacity(
          opacity: _followBottom ? 0 : 1,
          duration: const Duration(milliseconds: 150),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: FloatingActionButton(
              mini: true,
              clipBehavior: Clip.antiAlias,
              child: Icon(
                Icons.arrow_downward,
                color: widget.dark ? Colors.white : Colors.blue.shade900,
              ),
              onPressed: _scrollToBottom,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogContent() {
    return Stack(
      children: [
        Container(
            color: widget.dark ? Colors.black : Colors.grey.shade100,
            child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 1600,
                  child: ListView.builder(
                    shrinkWrap: true,
                    controller: _scrollController,
                    itemBuilder: (context, index) {
                      var logEntry = _filteredBuffer[index];
                      return SelectableText.rich(
                        logEntry.span,
                        key: Key(logEntry.id.toString()),
                        style: TextStyle(fontSize: _logFontSize),
                      );
                    },
                    itemCount: _filteredBuffer.length,
                  ),
                ))),
        _showQROverlay
            ? GestureDetector(
                child: Container(
                    child: SizedBox(
                        height: 200,
                        width: 200,
                        child: QrImage(
                          data: 'loggerId:${widget.loggerId}',
                          backgroundColor: Colors.white,
                        )),
                    alignment: Alignment.center,
                    color: Colors.black54),
                onTap: () {
                  setState(() {
                    _showQROverlay = false;
                  });
                })
            : Container()
      ],
    );
  }

  Widget _buildTopBar() {
    return LogBar(
      dark: widget.dark,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          const Text(
            "Log Console",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          widget.loggerId != null
              ? _buildLoggerIdWidget()
              : const SizedBox(width: 0, height: 0),
          IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                _renderedBuffer.clear();
                _refreshFilter();
              }),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _logFontSize++;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              setState(() {
                _logFontSize--;
              });
            },
          ),
          if (widget.showCloseButton)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLoggerIdWidget() {
    return Row(children: [
      OutlinedButton(
        child: QrImage(
            data: "loggerId:${widget.loggerId}",
            backgroundColor:
                widget.dark ? Colors.white : Colors.lightBlue.shade100),
        style: ButtonStyle(
            padding: MaterialStateProperty.all(EdgeInsets.zero),
            side: MaterialStateProperty.all(BorderSide.none)),
        onPressed: () {
          setState(() {
            _showQROverlay = true;
          });
        },
      ),
      const SizedBox(width: 10),
      const Text('loggerId => '),
      SelectableText(widget.loggerId!,
          style: const TextStyle(color: Colors.redAccent))
    ], mainAxisSize: MainAxisSize.min);
  }

  Widget _buildBottomBar() {
    return LogBar(
      dark: widget.dark,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: TextField(
              style: const TextStyle(fontSize: 20),
              controller: _filterController,
              onChanged: (s) => _refreshFilter(),
              decoration: const InputDecoration(
                labelText: "Filter log output",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 20),
          DropdownButton(
            value: _filterLevel,
            items: const [
              DropdownMenuItem(
                child: Text("VERBOSE"),
                value: Level.verbose,
              ),
              DropdownMenuItem(
                child: Text("DEBUG"),
                value: Level.debug,
              ),
              DropdownMenuItem(
                child: Text("INFO"),
                value: Level.info,
              ),
              DropdownMenuItem(
                child: Text("WARNING"),
                value: Level.warning,
              ),
              DropdownMenuItem(
                child: Text("ERROR"),
                value: Level.error,
              ),
              DropdownMenuItem(
                child: Text("WTF"),
                value: Level.wtf,
              )
            ],
            onChanged: (value) {
              _filterLevel = value as Level;
              _refreshFilter();
            },
          )
        ],
      ),
    );
  }

  void _scrollToBottom() async {
    _scrollListenerEnabled = false;

    setState(() {
      _followBottom = true;
    });

    var scrollPosition = _scrollController.position;
    _scrollController.jumpTo(scrollPosition.maxScrollExtent);
    // await _scrollController.animateTo(
    //   scrollPosition.maxScrollExtent,
    //   duration: const Duration(milliseconds: 300),
    //   curve: Curves.easeOut,
    // );

    _scrollListenerEnabled = true;
  }

  RenderedEvent _renderEvent(OutputEvent event) {
    var parser = AnsiParser(widget.dark);
    var text = event.lines.join('\n');
    parser.parse(text);
    return RenderedEvent(
      _currentId++,
      event.level,
      TextSpan(children: parser.spans),
      text.toLowerCase(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class LogBar extends StatelessWidget {
  final bool dark;
  final Widget child;

  const LogBar({Key? key, required this.dark, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            if (!dark)
              BoxShadow(
                color: Colors.grey.shade400,
                blurRadius: 3,
              ),
          ],
        ),
        child: Material(
          color: dark ? Colors.blueGrey.shade900 : Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
            child: child,
          ),
        ),
      ),
    );
  }
}
