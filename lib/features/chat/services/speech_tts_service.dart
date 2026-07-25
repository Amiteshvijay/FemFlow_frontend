import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechTtsService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isSpeechInitialized = false;
  bool _isTtsInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;

  Future<bool> initialize() async {
    if (!_isTtsInitialized) {
      try {
        await _tts.setSpeechRate(0.48);
        await _tts.setVolume(1.0);
        await _tts.setPitch(1.0);
        await _tts.awaitSpeakCompletion(true);
        _isTtsInitialized = true;
      } catch (e) {
        debugPrint('Error initializing FlutterTts: $e');
      }
    }

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
    await stopSpeaking();
    await initialize();

    _isSpeaking = true;
    onStart();

    String ttsLang = languageCode;
    if (languageCode == 'hi') ttsLang = 'hi-IN';
    if (languageCode == 'en') ttsLang = 'en-IN';

    try {
      await _tts.setLanguage(ttsLang);
    } catch (e) {
      debugPrint('Error setting TTS language $ttsLang: $e');
    }

    _tts.setStartHandler(() {
      _isSpeaking = true;
      onStart();
    });

    _tts.setCompletionHandler(() {
      if (_isSpeaking) {
        _isSpeaking = false;
        onDone();
      }
    });

    _tts.setErrorHandler((msg) {
      debugPrint('TTS Error: $msg');
      if (_isSpeaking) {
        _isSpeaking = false;
        onDone();
      }
    });

    try {
      final result = await _tts.speak(text);
      if (result == 0) {
        _isSpeaking = false;
        onDone();
      }
    } catch (e) {
      debugPrint('TTS speak exception: $e');
      _isSpeaking = false;
      onDone();
    }
  }

  Future<void> stopSpeaking() async {
    _isSpeaking = false;
    try {
      await _tts.stop();
    } catch (_) {}
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
