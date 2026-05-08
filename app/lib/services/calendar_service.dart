import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CalendarService {
  static const String baseUrl = 'http://127.0.0.1:8000';
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
  // 월/기간 단위 캘린더 이벤트 조회
  static Future<Map<String, dynamic>> getCalendarEvents({
    required String startDate,
    required String endDate,
    String cropName = '',
    String severityLevel = '',
    int? farmId,
    int? zoneId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': '토큰이 없습니다.'};
      }

      final queryParams = <String, String>{
        'start_date': startDate,
        'end_date': endDate,
      };

      if (cropName.isNotEmpty && cropName != '전체') {
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

      final uri = Uri.parse('$baseUrl/calendar/events').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data'] ?? []};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? '캘린더 이벤트 조회 실패',
        };
      }
    } catch (e) {
      return {'success': false, 'message': '서버 연결 실패: $e'};
    }
  }

  // 특정 날짜 이벤트 조회
  static Future<Map<String, dynamic>> getEventsByDate({
    required String selectedDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': '토큰이 없습니다.'};
      }

      final uri = Uri.parse('$baseUrl/calendar/events/by-date').replace(
        queryParameters: {
          'date': selectedDate,
        },
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data'] ?? []};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? '날짜별 이벤트 조회 실패',
        };
      }
    } catch (e) {
      return {'success': false, 'message': '서버 연결 실패: $e'};
    }
  }

  static Future<Map<String, dynamic>> getTreatmentAlerts({
    String cropName = '',
    String severityLevel = '',
    int? farmId,
    int? zoneId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': '토큰이 없습니다.'};
      }

      final queryParams = <String, String>{};

      if (cropName.isNotEmpty && cropName != '전체') {
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

      final uri = Uri.parse('$baseUrl/alerts/treatment').replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? '조치 목록 조회 실패',
        };
      }
    } catch (e) {
      return {'success': false, 'message': '서버 연결 실패: $e'};
    }
  }

  static Future<Map<String, dynamic>> respondAlert({
    required int alertId,
    required String alertResponse,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': '토큰이 없습니다.'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/alerts/$alertId/respond'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'alert_response': alertResponse}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? '알림 응답 처리 실패',
        };
      }
    } catch (e) {
      return {'success': false, 'message': '서버 연결 실패: $e'};
    }
  }

  static Future<Map<String, dynamic>> createTreatmentAlert({
    required int diagnosisId,
    required String scheduledAt,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': '토큰이 없습니다.'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/alerts/treatment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'diagnosis_id': diagnosisId,
          'scheduled_at': scheduledAt,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? '알림 설정 실패',
        };
      }
    } catch (e) {
      return {'success': false, 'message': '서버 연결 실패: $e'};
    }
  }
}