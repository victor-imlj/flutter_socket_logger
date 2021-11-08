import 'package:logger/logger.dart';

class ProductFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    var shouldLog = false;
    if (event.level.index >= level!.index) {
      shouldLog = true;
    }
    return shouldLog;
  }
}
