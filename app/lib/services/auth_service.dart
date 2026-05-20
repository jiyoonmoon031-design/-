import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8000'; 
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
  static Future<Map<String, dynamic>> updateMyRole(String userRole) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.patch(
      Uri.parse('$baseUrl/users/me/role'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'user_role': userRole,
      }),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': data['message'] ?? '역할이 변경되었습니다.',
        'data': data['data'],
      };
    }

    return {
      'success': false,
      'message': data['detail'] ?? '역할 변경에 실패했습니다.',
    };
  }
  static Future<Map<String, dynamic>> updateMyInfo(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.patch(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
      }),
    );

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> updateMyPassword(
    String currentPassword,
    String newPassword,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    print('currentPassword: $currentPassword');
    print('newPassword: $newPassword');
    
    final response = await http.patch(
      Uri.parse('$baseUrl/users/me/password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    print('비밀번호 변경 status: ${response.statusCode}');
    print('비밀번호 변경 body: ${response.body}');

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> updateNotificationSetting(
    bool notificationEnabled,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.patch(
      Uri.parse('$baseUrl/users/me/notification'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'notification_enabled': notificationEnabled,
      }),
    );

    return jsonDecode(utf8.decode(response.bodyBytes));
  }
  static Future<Map<String, dynamic>> deleteMyAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.delete(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return jsonDecode(utf8.decode(response.bodyBytes));
  }
  static Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String token,
    required String userRole,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/social-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'provider': provider,
        'token': token,
        'user_role': userRole,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'access_token',
        data['access_token'],
      );
    }

    return data;  
  }
  static Future<Map<String, dynamic>> sendResetCode(
    String email,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-reset-code'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ?? '인증번호 발송 실패',
      );
    }

    return data;
  }
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'code': code,
        'new_password': newPassword,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ?? '비밀번호 변경 실패',
      );
    }

    return data;
  }
}