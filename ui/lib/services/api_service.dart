import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:6060/api';

  Future<String> createInvite() async {
    final response = await http.post(Uri.parse('$baseUrl/invite'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['token'] as String;
    }
    throw Exception('Failed to create invite token');
  }

  Future<Map<String, dynamic>> requestInvite(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/request-invite'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to request invite');
  }

  Future<Map<String, dynamic>> register(String email, String username,
      String password, String inviteToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'username': username,
        'password': password,
        'invite_token': inviteToken,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Registration failed');
  }

  Future<Map<String, dynamic>> login(
      String emailOrUsername, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email_or_username': emailOrUsername,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Login failed');
  }

  Future<Map<String, dynamic>> getProtectedData(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/protected'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to get protected data');
  }

  Future<Map<String, dynamic>> getInvites(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/invites'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to fetch invites');
  }

  Future<String> createInviteWithToken(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/invite'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['token'] as String;
    }
    throw Exception('Failed to create invite');
  }

  Future<void> updateProfile(
    String token, {
    required String email,
    required String username,
    String? currentPassword,
    String? newPassword,
  }) async {
    final body = {
      'email': email,
      'username': username,
    };

    if (currentPassword != null && currentPassword.isNotEmpty) {
      body['current_password'] = currentPassword;
    }
    if (newPassword != null && newPassword.isNotEmpty) {
      body['new_password'] = newPassword;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile');
    }
  }
}
