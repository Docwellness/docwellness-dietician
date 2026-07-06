import 'dart:developer';

import 'package:docwellnesdoc/app/utils/functions/dio_function.dart';
import 'package:docwellnesdoc/main.dart';

class CouponService {
  final ApiService _api = ApiService();

  /// Fetch all coupons for the dietician
  Future<List<Map<String, dynamic>>> getCoupons() async {
    try {
      final res = await _api.request(
        endPoint: '/coupons',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res != null && res.statusCode == 200 && res.data['success'] == true) {
        return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
      }
      return [];
    } catch (e) {
      log('CouponService.getCoupons error: $e');
      return [];
    }
  }

  /// Add a new coupon
  Future<Map<String, dynamic>?> addCoupon({
    required String name,
    required String code,
    required int discountPercentage,
    required String validTill,
    required bool isActive,
  }) async {
    try {
      final res = await _api.request(
        endPoint: '/coupons',
        method: 'POST',
        data: {
          'name': name,
          'code': code,
          'discountPercentage': discountPercentage,
          'validTill': validTill,
          'isActive': isActive,
        },
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res != null &&
          (res.statusCode == 200 || res.statusCode == 201) &&
          res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      log('CouponService.addCoupon error: $e');
      return null;
    }
  }

  /// Update an existing coupon
  Future<Map<String, dynamic>?> updateCoupon({
    required String couponId,
    String? name,
    String? code,
    int? discountPercentage,
    String? validTill,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (code != null) data['code'] = code;
      if (discountPercentage != null) {
        data['discountPercentage'] = discountPercentage;
      }
      if (validTill != null) data['validTill'] = validTill;
      if (isActive != null) data['isActive'] = isActive;

      final res = await _api.request(
        endPoint: '/coupons/$couponId',
        method: 'PUT',
        data: data,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res != null && res.statusCode == 200 && res.data['success'] == true) {
        return res.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      log('CouponService.updateCoupon error: $e');
      return null;
    }
  }

  /// Delete a coupon by ID
  Future<bool> deleteCoupon(String couponId) async {
    try {
      final res = await _api.request(
        endPoint: '/coupons/$couponId',
        method: 'DELETE',
        headers: {'Authorization': 'Bearer $token'},
      );
      return res != null &&
          res.statusCode == 200 &&
          res.data['success'] == true;
    } catch (e) {
      log('CouponService.deleteCoupon error: $e');
      return false;
    }
  }
}
