import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  late final Dio _dio;
  String? _token;

  // Toggle this flag to switch between local development and the deployed production backend.
  // Set to true to connect any device over the internet to the deployed server.
  static const bool useDeployedBackend = true;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    const String deployedUrl = 'https://aatzy-mart-app.vercel.app/api';
    const String localUrl = kIsWeb 
        ? 'http://localhost:5000/api' 
        : 'http://10.118.69.2:5000/api';

    const String baseUrlAddress = useDeployedBackend ? deployedUrl : localUrl;

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrlAddress,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          debugPrint('API Error: ${e.response?.statusCode} - ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }

  void setToken(String? token) {
    _token = token;
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
        // Fallback or bubble up custom exceptions
      }
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } catch (e) {
      rethrow;
    }
  }
}
