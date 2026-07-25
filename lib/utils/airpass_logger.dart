import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

/// A centralized logger for the Airpass package that exposes a stream
/// of log messages for the UI to subscribe to.
class AirpassLogger {
  static final StreamController<String> _logController =
      StreamController<String>.broadcast();

  /// A broadcast stream of all internal airpass logs.
  /// The UI can listen to this stream to display debug logs.
  static Stream<String> get logStream => _logController.stream;

  /// Logs a message to the console and adds it to the log stream.
  static void log(String tag, String message) {
    final formattedMessage = '[$tag] $message';
    debugPrint(formattedMessage);
    dev.log(message, name: tag);
    _logController.add(formattedMessage);
  }
}
