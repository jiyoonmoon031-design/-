import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AlertService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  static Future<void> saveFcmToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null) {
      throw Exception('로그인 토큰이 없습니다.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/users/fcm-token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'fcm_token': token,
        'platform': 'windows',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('FCM 토큰 저장 실패: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> respondTreatmentAlert({
    required int alertId,
    required String alertResponse,
    DateTime? nextScheduledAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null) {
      throw Exception('로그인 토큰이 없습니다.');
    }

    final body = {
      'alert_response': alertResponse,
      if (nextScheduledAt != null)
        'next_scheduled_at': nextScheduledAt.toIso8601String(),
    };

    final response = await http.post(
      Uri.parse('$baseUrl/alerts/$alertId/respond'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(body),
    );

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> createTreatmentAlert({
    required int diagnosisId,
    required String scheduledAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null) {
      return {
        'success': false,
        'message': '로그인 토큰이 없습니다.',
      };
    }

    final response = await http.post(
      Uri.parse('$baseUrl/alerts/treatment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'diagnosis_id': diagnosisId,
        'scheduled_at': scheduledAt,
      }),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': data,
      };
    } else {
      return {
        'success': false,
        'message': data['detail'] ?? '알림 생성 실패',
      };
   }
  }

  static Future<Map<String, dynamic>> getTreatmentAlerts({
    String cropName = '',
    String severityLevel = '',
    int? farmId,
    int? zoneId,
    String alertStatus = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null) {
      return {
        'success': false,
        'message': '로그인 토큰이 없습니다.',
      };
    }

    final queryParams = <String, String>{};

    if (cropName.isNotEmpty) {
      queryParams['crop_name'] = cropName;
    }

    if (severityLevel.isNotEmpty) {
      queryParams['severity_level'] = severityLevel;
    }

    if (farmId != null) {
      queryParams['farm_id'] = farmId.toString();
    }

    if (zoneId != null) {
      queryParams['zone_id'] = zoneId.toString();
    }

    if (alertStatus.isNotEmpty) {
      queryParams['alert_status'] = alertStatus;
    }

    final uri = Uri.parse(
      '$baseUrl/alerts/treatment',
    ).replace(
      queryParameters: queryParams,
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': data['data'],
      };
    } else {
      return {
        'success': false,
        'message': data['detail'] ?? '조치 알림 조회 실패',
      };
    }
  }
  static Future<Map<String, dynamic>> getAlertDetail(int alertId) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null) {
      return {
        'success': false,
        'message': '로그인 토큰이 없습니다.',
      };
    }

    final response = await http.get(
      Uri.parse('$baseUrl/alerts/$alertId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return data;
    }

    return {
      'success': false,
      'message': data['detail'] ?? '알림 정보를 불러오지 못했습니다.',
    };
  }
}