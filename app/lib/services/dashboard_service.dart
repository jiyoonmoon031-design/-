import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<Map<String, dynamic>> getDashboard({
    int? farmId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': '토큰이 없습니다.'};
      }

      final queryParams = <String, String>{};

      if (farmId != null) {
        queryParams['farm_id'] = farmId.toString();
      }

      final uri = Uri.parse('$baseUrl/dashboard').replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      }

      return {
        'success': false,
        'message': data['detail'] ?? '전체 KPI 조회 실패',
      };
    } catch (e) {
      return {'success': false, 'message': '서버 연결 실패: $e'};
    }
  }

  static Future<Map<String, dynamic>> getGroupKpi() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': '토큰이 없습니다.'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/group-kpi'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data'] ?? []};
      }

      return {
        'success': false,
        'message': data['detail'] ?? '그룹 KPI 조회 실패',
      };
    } catch (e) {
      return {'success': false, 'message': '서버 연결 실패: $e'};
    }
  }

  static Future<Map<String, dynamic>> getGroupCharts({
    String? cropName,
    int? farmId,
    int? zoneId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': '토큰이 없습니다.'};
      }

      final queryParams = <String, String>{};

      if (cropName != null && cropName.isNotEmpty) {
        queryParams['crop_name'] = cropName;
      }

      if (farmId != null) {
        queryParams['farm_id'] = farmId.toString();
      }

      if (zoneId != null) {
        queryParams['zone_id'] = zoneId.toString();
      }

      final uri = Uri.parse('$baseUrl/dashboard/group-charts').replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      }

      return {
        'success': false,
        'message': data['detail'] ?? '그래프 조회 실패',
      };
    } catch (e) {
      return {'success': false, 'message': '서버 연결 실패: $e'};
    }
  }
}