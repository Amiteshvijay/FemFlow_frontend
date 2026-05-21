import 'package:flutter/material.dart';
import '../data/tips_service.dart';
import '../models/tips_models.dart';

class TipsProvider extends ChangeNotifier {
  final TipsService _service = TipsService();
  
  UserDailyTipsResponse? _dailyTips;
  bool _isLoading = false;
  String? _error;

  UserDailyTipsResponse? get dailyTips => _dailyTips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDailyTips() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Fetching daily tips...');
      _dailyTips = await _service.getDailyTips();
      debugPrint('Fetched ${_dailyTips?.tips.length} tips');
    } catch (e) {
      debugPrint('Error loading tips: $e');
      _error = 'We encountered an issue while personalizing your tips. Please try again.';
      if (e.toString().contains('Failed host lookup')) {
        _error = 'No internet connection. Please check your network.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<DailyTipDetailModel?> getTipDetail(String tipKey) async {
    try {
      return await _service.getTipDetail(tipKey);
    } catch (e) {
      debugPrint('Error fetching tip detail: $e');
      return null;
    }
  }

  void reset() {
    _dailyTips = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
