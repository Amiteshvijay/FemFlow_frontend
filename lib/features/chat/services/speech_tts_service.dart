import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechTtsService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSpeechInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;

  Future<bool> initialize() async {
    if (_isSpeechInitialized) return true;
    try {
      _isSpeechInitialized = await _speech.initialize(
        onError: (error) => debugPrint('STT Error: $error'),
        onStatus: (status) => debugPrint('STT Status: $status'),
      );
      return _isSpeechInitialized;
    } catch (e) {
      debugPrint('Error initializing SpeechToText: $e');
      return false;
    }
  }

  Future<void> startListening({
    required String localeId,
    required Function(String text, bool isFinal) onResult,
    required Function() onListeningComplete,
  }) async {
    final available = await initialize();
    if (!available) {
      onListeningComplete();
      return;
    }

    _isListening = true;
    await _speech.listen(
      localeId: localeId,
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
        if (result.finalResult) {
          _isListening = false;
          onListeningComplete();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      partialResults: true,
    );
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  Future<void> speak({
    required String text,
    required String languageCode,
    required Function() onStart,
    required Function() onDone,
  }) async {
    _isSpeaking = true;
    onStart();

    // Standard duration simulation / voice engine handler for mobile web & native
    final wordCount = text.split(' ').length;
    final estimatedSeconds = (wordCount / 2.5).clamp(3.0, 20.0);

    debugPrint('FemAI Speaking ($languageCode): $text');

    // Simulate completion or allow manual stop
    Future.delayed(Duration(seconds: estimatedSeconds.round()), () {
      if (_isSpeaking) {
        _isSpeaking = false;
        onDone();
      }
    });
  }

  Future<void> stopSpeaking() async {
    _isSpeaking = false;
  }

  Future<void> replay({
    required String text,
    required String languageCode,
    required Function() onStart,
    required Function() onDone,
  }) async {
    await stopSpeaking();
    await speak(
      text: text,
      languageCode: languageCode,
      onStart: onStart,
      onDone: onDone,
    );
  }
}
