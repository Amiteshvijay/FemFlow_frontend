import 'package:flutter/material.dart';
import '../data/subscription_service.dart';
import '../models/subscription_models.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _service = SubscriptionService();
  
  UserSubscriptionStatus? _status;
  List<SubscriptionPlan> _plans = [];
  List<InvoiceModel> _invoices = [];
  bool _isLoading = false;
  String? _error;

  UserSubscriptionStatus? get status => _status;
  List<SubscriptionPlan> get plans => _plans;
  List<InvoiceModel> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isPremium => _status?.hasPremiumAccess ?? false;

  Future<String?> getToken() async {
    return await _service.getToken();
  }

  Future<void> loadStatus() async {
    _isLoading = true;
    notifyListeners();
    try {
      _status = await _service.getStatus();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPlans() async {
    try {
      _plans = await _service.getPlans();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading plans: $e');
    }
  }

  Future<bool> startTrial() async {
    _isLoading = true;
    notifyListeners();
    try {
      _status = await _service.startTrial();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelSubscription() async {
    _isLoading = true;
    notifyListeners();
    try {
      _status = await _service.cancelSubscription();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> initiateCancellation() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.initiateCancellation();
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyCancellation(String otp) async {
    _isLoading = true;
    notifyListeners();
    try {
      _status = await _service.verifyCancellation(otp);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyPayment(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      _status = await _service.verifyPayment(data);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadInvoices() async {
    _isLoading = true;
    notifyListeners();
    try {
      _invoices = await _service.getInvoices();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _status = null;
    _plans = [];
    _invoices = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
