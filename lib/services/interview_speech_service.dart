import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Shared recognizer so permission and platform initialization happen only once.
final interviewSpeechService = InterviewSpeechService();

class InterviewSpeechService extends ChangeNotifier {
  final SpeechToText speech = SpeechToText();
  Future<bool>? _initialization;
  bool available = false;
  bool listening = false;
  String error = '';

  Future<bool> initialize() => _initialization ??= _initialize();

  Future<bool> _initialize() async {
    try {
      available = await speech.initialize(
        onStatus: (status) {
          listening = status == 'listening';
          notifyListeners();
        },
        onError: (errorResult) {
          listening = false;
          error = errorResult.errorMsg;
          notifyListeners();
        },
      );
      if (!available) {
        error = 'Speech recognition is unavailable. Check microphone access and your device speech service.';
      }
    } catch (_) {
      available = false;
      error = 'Could not access speech recognition on this device.';
    }
    notifyListeners();
    return available;
  }

  void clearError() {
    error = '';
    notifyListeners();
  }

  void setError(String message) {
    error = message;
    notifyListeners();
  }
}
