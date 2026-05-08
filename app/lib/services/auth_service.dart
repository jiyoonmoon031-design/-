import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:8000'; 
  // Android Emulator 기준
  // 실제 폰이면 PC IP로 바꿔야 함

  static Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String name,
    required String userRole,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'user_role': userRole,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': data['message'],
      };  
    } else {
      String message;

      if (data['message'] != null) {
        message = data['message'].toString();
      } else if (data['detail'] is List) {
        message = data['detail'][0]['msg']; // 👈 핵심
      } else if (data['detail'] != null) {
        message = data['detail'].toString();
      } else {
       message = '회원가입 실패';
      }

      return {
        'success': false,
        'message': message,
      };
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access_token']);

      return {
        'success': true,
        'user': data['user'],
      };
    } else {
      return {
        'success': false,
        'message': data['detail'] ?? '로그인 실패',
      };
    }
  }

  static Future<Map<String, dynamic>?> getMyInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }
}