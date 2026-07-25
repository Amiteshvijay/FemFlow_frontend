import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../models/user_address.dart';

class AddressService {
  final ApiClient _apiClient = ApiClient();

  Future<List<UserAddress>> getAddresses() async {
    try {
      final response = await _apiClient.get('/users/addresses/');
      if (response is List) {
        return response.map((json) => UserAddress.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Failed to load user addresses: $e');
      rethrow;
    }
  }

  Future<UserAddress> addAddress(UserAddress address) async {
    final response = await _apiClient.post(
      '/users/addresses/',
      body: address.toJson(),
    );
    return UserAddress.fromJson(response as Map<String, dynamic>);
  }

  Future<UserAddress> updateAddress(int id, UserAddress address) async {
    final response = await _apiClient.put(
      '/users/addresses/$id/',
      body: address.toJson(),
    );
    return UserAddress.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteAddress(int id) async {
    await _apiClient.delete('/users/addresses/$id/');
  }

  Future<UserAddress> setDefaultAddress(int id) async {
    final response = await _apiClient.post('/users/addresses/$id/set_default/', body: {});
    return UserAddress.fromJson(response as Map<String, dynamic>);
  }
}
