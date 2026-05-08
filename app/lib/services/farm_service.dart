import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FarmService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<Map<String, dynamic>> getFarms() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': '토큰이 없습니다.'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/farms'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? '농장 조회 실패',
        };
      }
    } catch (e) {
      return {'success': false, 'message': '서버 연결 실패: $e'};
    }
  }

  static Future<Map<String, dynamic>> createFarm({
    required String farmName,
    String? farmLocation,
    String? farmDescription,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': '토큰이 없습니다.'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/farms'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'farm_name': farmName,
          'farm_location': farmLocation,
          'farm_description': farmDescription,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? '농장 등록 실패',
        };
      }
    } catch (e) {
      return {'success': false, 'message': '서버 연결 실패: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateFarm({
    required int farmId,
    required String farmName,
    String? farmLocation,
    String? farmDescription,
  }) async {
    final token = await _getToken();

    final response = await http.patch(
      Uri.parse('$baseUrl/farms/$farmId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'farm_name': farmName,
        'farm_location': farmLocation,
        'farm_description': farmDescription,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {'success': true, 'message': data['message']};
    }

    return {'success': false, 'message': data['detail'] ?? '농장 수정 실패'};
  }

  static Future<Map<String, dynamic>> deleteFarm(int farmId) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/farms/$farmId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {'success': true, 'message': data['message']};
    }

    return {'success': false, 'message': data['detail'] ?? '농장 삭제 실패'};
  }

  static Future<Map<String, dynamic>> getZones(int farmId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': '토큰이 없습니다.'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/zones?farm_id=$farmId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? '구역 조회 실패',
        };
      }
    } catch (e) {
      return {'success': false, 'message': '서버 연결 실패: $e'};
    }
  }

  static Future<Map<String, dynamic>> createZone({
    required int farmId,
    required String zoneNameOrCode,
    String? buildingName,
    String? bedName,
    String? cropName,
    String? zoneDescription,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': '토큰이 없습니다.'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/zones'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'farm_id': farmId,
          'zone_name_or_code': zoneNameOrCode,
          'building_name': buildingName,
          'bed_name': bedName,
          'crop_name': cropName,
          'zone_description': zoneDescription,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? '구역 등록 실패',
        };
      }
    } catch (e) {
      return {'success': false, 'message': '서버 연결 실패: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateZone({
    required int zoneId,
    required String zoneNameOrCode,
    String? buildingName,
    String? bedName,
    String? cropName,
    String? zoneDescription,
  }) async {
    final token = await _getToken();

    final response = await http.patch(
      Uri.parse('$baseUrl/zones/$zoneId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'zone_name_or_code': zoneNameOrCode,
        'building_name': buildingName,
        'bed_name': bedName,
        'crop_name': cropName,
        'zone_description': zoneDescription,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {'success': true, 'message': data['message']};
    }

    return {'success': false, 'message': data['detail'] ?? '구역 수정 실패'};
  }
  
  static Future<Map<String, dynamic>> deleteZone(int zoneId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': '토큰이 없습니다.'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/zones/$zoneId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? '구역이 삭제되었습니다.',
        };
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? '구역 삭제 실패',
        };
      }
    } catch (e) {
      return {'success': false, 'message': '서버 연결 실패: $e'};
    }
  }


  Future<void> updateShareConsent({
    required int farmId,
    required String shareConsentLevel,
    required List<int> sharedZoneIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.patch(
      Uri.parse('$baseUrl/farms/$farmId/share-consent'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'share_consent_level': shareConsentLevel,
        'shared_zone_ids': sharedZoneIds,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception("공유 동의 실패");
    }
  }

  static Future<Map<String, dynamic>> getNearbyFarms({
    required int baseFarmId,
    double radiusKm = 30,
    String sortBy = 'distance',
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': '토큰이 없습니다.'};
      }

      final response = await http.get(
        Uri.parse(
          '$baseUrl/farms/nearby?base_farm_id=$baseFarmId&radius_km=$radiusKm&sort_by=$sortBy',
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      }

      return {
        'success': false,
        'message': data['detail'] ?? '인근 농장 조회 실패',
      };
    } catch (e) {
      return {'success': false, 'message': '서버 연결 실패: $e'};
    }
  }

  static Future<Map<String, dynamic>> getNearbyFarmRiskDetail({
    required int farmId,
    required int baseFarmId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': '토큰이 없습니다.'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/farms/nearby/$farmId/risk-detail?base_farm_id=$baseFarmId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      }

      return {
        'success': false,
        'message': data['detail'] ?? '인근 농장 상세 조회 실패',
      };
    } catch (e) {
      return {'success': false, 'message': '서버 연결 실패: $e'};
    }
  }
}