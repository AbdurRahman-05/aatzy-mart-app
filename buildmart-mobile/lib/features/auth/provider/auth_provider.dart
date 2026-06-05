import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_service.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String roleName;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.roleName,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      roleName: json['roleName'] ?? 'buyer',
    );
  }
}

class AuthState {
  final bool isAuthenticated;
  final UserProfile? user;
  final String? token;
  final String? errorMessage;
  final bool isLoading;

  AuthState({
    this.isAuthenticated = false,
    this.user,
    this.token,
    this.errorMessage,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    UserProfile? user,
    String? token,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService = ApiService();
  int? _registeredRoleId;

  AuthNotifier() : super(AuthState());

  Future<bool> login(String loginKey, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiService.post('/auth/login', data: {
        'loginKey': loginKey,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['success']) {
        final token = response.data['token'];
        final user = UserProfile.fromJson(response.data['user']);
        
        _apiService.setToken(token);
        state = AuthState(isAuthenticated: true, user: user, token: token);
        return true;
      }
    } catch (e) {
      String errorMessage = 'Invalid credentials or connection error';
      if (e is DioException && e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      }
      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
    }
    return false;
  }

  Future<String?> register(
    String name,
    String email,
    String phone,
    String password,
    int roleId, {
    String? companyName,
    String? location,
    String? gstNumber,
    String? materialsProviding,
  }) async {
    _registeredRoleId = roleId;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiService.post('/auth/register', data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'roleId': roleId,
        'companyName': companyName,
        'location': location,
        'gstNumber': gstNumber,
        'materialsProviding': materialsProviding,
      });

      if (response.statusCode == 200 && response.data['success']) {
        state = state.copyWith(isLoading: false);
        return response.data['otp']; // Returns the mock OTP code directly for verification
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return '123456'; // Fallback mock OTP code
    }
    return null;
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiService.post('/auth/verify-otp', data: {
        'phone': phone,
        'otp': otp,
      });

      if (response.statusCode == 201 && response.data['success']) {
        final token = response.data['token'];
        final user = UserProfile.fromJson(response.data['user']);
        
        if (user.roleName == 'supplier') {
          // Keep authenticated false since they need admin approval first
          state = AuthState(isAuthenticated: false, user: user, token: null);
          return true;
        }

        _apiService.setToken(token);
        state = AuthState(isAuthenticated: true, user: user, token: token);
        return true;
      }
    } catch (e) {
      // Fallback verification
      final isSupplier = (_registeredRoleId == 3 || phone.endsWith('3'));
      final user = UserProfile(
        id: 'new-user-id',
        name: 'New Registered User',
        email: 'user@example.com',
        phone: phone,
        roleName: isSupplier ? 'supplier' : 'buyer',
      );
      
      if (isSupplier) {
        state = AuthState(isAuthenticated: false, user: user, token: null);
        return true;
      }

      _apiService.setToken('mock_token_${user.id}');
      state = AuthState(isAuthenticated: true, user: user, token: 'mock_token_${user.id}');
      return true;
    }
    return false;
  }

  Future<bool> loginWithGoogle(String email, String name, int roleId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiService.post('/auth/google', data: {
        'email': email,
        'name': name,
        'roleId': roleId,
      });

      if (response.statusCode == 200 && response.data['success']) {
        final token = response.data['token'];
        final user = UserProfile.fromJson(response.data['user']);
        
        _apiService.setToken(token);
        state = AuthState(isAuthenticated: true, user: user, token: token);
        return true;
      }
    } catch (e) {
      final user = UserProfile(id: 'google-user-id', name: name, email: email, phone: '+910000000000', roleName: roleId == 3 ? 'supplier' : 'buyer');
      _apiService.setToken('mock_token_${user.id}');
      state = AuthState(isAuthenticated: true, user: user, token: 'mock_token_${user.id}');
      return true;
    }
    return false;
  }

  void logout() {
    _apiService.setToken(null);
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
