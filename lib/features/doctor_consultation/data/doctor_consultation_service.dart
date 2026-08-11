import 'dart:typed_data';
import 'package:femlyra/core/network/api_client.dart';
import '../models/doctor_models.dart';

class DoctorConsultationService {
  final ApiClient _apiClient = ApiClient();

  Future<List<DoctorCategory>> getCategories() async {
    final response = await _apiClient.get('/doctor-consultation/categories/');
    final List<dynamic> data = response;
    return data.map((json) => DoctorCategory.fromJson(json)).toList();
  }

  Future<List<DoctorProfile>> getDoctors({
    String? category,
    String? search,
    double? minPrice,
    double? maxPrice,
    bool? available,
  }) async {
    String endpoint = '/doctor-consultation/doctors/';
    final Map<String, String> queryParams = {};
    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;
    if (minPrice != null) queryParams['min_price'] = minPrice.toString();
    if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
    if (available != null) queryParams['available'] = available.toString();
    
    if (queryParams.isNotEmpty) {
      final uri = Uri(path: '', queryParameters: queryParams);
      endpoint = '$endpoint${uri.toString()}';
    }

    final response = await _apiClient.get(endpoint);
    final List<dynamic> data = response;
    return data.map((json) => DoctorProfile.fromJson(json)).toList();
  }

  Future<DoctorProfile> getDoctorDetail(int id) async {
    final response = await _apiClient.get('/doctor-consultation/doctors/$id/');
    return DoctorProfile.fromJson(response);
  }

  Future<List<Map<String, dynamic>>> getAvailableSlots(int id, String date) async {
    final response = await _apiClient.get('/doctor-consultation/doctors/$id/slots/?date=$date');
    final List<dynamic> data = response['slots'];
    return data.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> createBooking({
    required int doctorId,
    required String consultationMode,
    required String appointmentDate,
    required String appointmentTime,
    String? userNotes,
    bool isCommunityCare = false,
    int? originalBookingId,
    String? couponCode,
  }) async {
    final response = await _apiClient.post('/doctor-consultation/bookings/', body: {
      'doctor_id': doctorId,
      'consultation_mode': consultationMode,
      'appointment_date': appointmentDate,
      'appointment_time': appointmentTime,
      'user_notes': userNotes,
      'is_community_care': isCommunityCare,
      'original_booking_id': originalBookingId,
      'coupon_code': couponCode,
      'referral_code': couponCode,
    });
    return response;
  }

  Future<void> submitUtr(int bookingId, String utrNumber, dynamic screenshotFile) async {
    await _apiClient.multipartPost(
      '/doctor-consultation/bookings/$bookingId/submit-utr/',
      fields: {
        'utr_number': utrNumber,
      },
      fileFieldName: 'payment_screenshot',
      file: screenshotFile,
    );
  }

  Future<void> updatePaymentStage(String orderId, String stage, [Map<String, dynamic>? metadata]) async {
    try {
      await _apiClient.post('/doctor-consultation/payment/update-stage/', body: {
        'order_id': orderId,
        'stage': stage,
        'metadata': metadata ?? {},
      });
    } catch (e) {
      // Fail silently to not block user checkout
      print('DEBUG: Failed to update doctor payment stage: $e');
    }
  }

  Future<Map<String, dynamic>> createRazorpayOrder(int bookingId) async {
    final response = await _apiClient.post('/doctor-consultation/bookings/$bookingId/create-payment-order/');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyRazorpayPayment(int bookingId, Map<String, dynamic> data) async {
    final response = await _apiClient.post('/doctor-consultation/bookings/$bookingId/verify-payment/', body: data);
    return response as Map<String, dynamic>;
  }

  Future<List<DoctorBooking>> getMyBookings() async {
    final response = await _apiClient.get('/doctor-consultation/my-bookings/');
    final List<dynamic> data = response;
    return data.map((json) => DoctorBooking.fromJson(json)).toList();
  }

  Future<DoctorBooking> getBookingDetail(int id) async {
    final response = await _apiClient.get('/doctor-consultation/bookings/$id/');
    return DoctorBooking.fromJson(response);
  }

  Future<Invoice> getInvoice(int bookingId) async {
    final response = await _apiClient.get('/doctor-consultation/bookings/$bookingId/invoice/');
    return Invoice.fromJson(response);
  }

  Future<Uint8List> downloadInvoicePdf(int bookingId) async {
    return await _apiClient.downloadFile('/doctor-consultation/bookings/$bookingId/invoice/download/');
  }

  Future<Map<String, dynamic>> emailInvoice(int bookingId) async {
    final response = await _apiClient.post('/doctor-consultation/bookings/$bookingId/invoice/email/', body: {});
    return response;
  }

  Future<Map<String, dynamic>> cancelBooking(int bookingId) async {
    final response = await _apiClient.post('/doctor-consultation/bookings/$bookingId/cancel/', body: {});
    return response;
  }

  Future<Map<String, dynamic>> rescheduleBooking({
    required int bookingId,
    required String appointmentDate,
    required String appointmentTime,
  }) async {
    final response = await _apiClient.post('/doctor-consultation/bookings/$bookingId/reschedule/', body: {
      'appointment_date': appointmentDate,
      'appointment_time': appointmentTime,
    });
    return response;
  }

  Future<DoctorReview> submitReview({
    required int bookingId,
    required int rating,
    required List<String> quickTags,
    String? reviewText,
  }) async {
    final response = await _apiClient.post('/doctor-consultation/bookings/$bookingId/submit-review/', body: {
      'booking': bookingId,
      'rating': rating,
      'quick_tags': quickTags,
      'review_text': reviewText,
    });
    return DoctorReview.fromJson(response);
  }

  Future<Prescription> getPrescription(int bookingId) async {
    final response = await _apiClient.get('/doctor-consultation/bookings/$bookingId/prescription/');
    return Prescription.fromJson(response);
  }

  Future<Uint8List> downloadPrescriptionPdf(int bookingId) async {
    return await _apiClient.downloadFile('/doctor-consultation/bookings/$bookingId/prescription/download/');
  }

  Future<Map<String, dynamic>> enrollCareProgram() async {
    final response = await _apiClient.post('/doctor-consultation/portal/care-program/enroll/', body: {});
    return response;
  }
}
