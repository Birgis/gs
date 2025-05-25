import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _token;
  bool _isLoading = false;

  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  Future<void> init() async {
    _token = await _storage.read(key: 'token');
    notifyListeners();
  }

  Future<String> createInvite() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _apiService.createInvite();
      _isLoading = false;
      notifyListeners();
      return token;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> register(String email, String username, String password,
      String inviteToken) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response =
          await _apiService.register(email, username, password, inviteToken);
      final token = response['data']?['token'];
      if (token == null) {
        throw Exception('No token returned from server');
      }
      _token = token as String;
      await _storage.write(key: 'token', value: _token);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> login(String emailOrUsername, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(emailOrUsername, password);
      final token = response['data']?['token'];
      if (token == null) {
        throw Exception('No token returned from server');
      }
      _token = token as String;
      await _storage.write(key: 'token', value: _token);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: 'token');
    notifyListeners();
  }
}
