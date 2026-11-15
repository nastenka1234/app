import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class ApiError implements Exception {
  final String code;
  final int status;
  ApiError(this.code, this.status);
  bool get isNetwork => status == 0;

  String get fa {
    switch (code) {
      case 'wrong_password':
        return 'رمز اشتباه است';
      case 'account_disabled':
        return 'این حساب غیرفعال شده است';
      case 'too_many_attempts':
        return 'تلاش زیاد؛ ۱۰ دقیقه‌ی دیگر دوباره امتحان کن';
      case 'password_in_use':
        return 'این رمز قبلاً استفاده شده';
      case 'network':
        return 'اتصال برقرار نشد';
      default:
        return 'خطا: $code';
    }
  }

  @override
  String toString() => code;
}

class Api {
  Api._();
  static final Api i = Api._();

  final _sec = const FlutterSecureStorage();
  late Dio dio;
  String? token;
  String baseUrl = Config.defaultBaseUrl;
  void Function()? onUnauthorized;
  void Function()? onDisabled;

  String get _root => baseUrl.replaceAll(RegExp(r'/+$'), '');

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    baseUrl = p.getString('baseUrl') ?? Config.defaultBaseUrl;
    token = await _sec.read(key: 'token');
    _build();
  }

  void _build() {
    dio = Dio(BaseOptions(
      baseUrl: '$_root/api',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 40),
      sendTimeout: const Duration(minutes: 5),
    ));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      if (token != null) o.headers['Authorization'] = 'Bearer $token';
      h.next(o);
    }));
  }

  Future<void> setBaseUrl(String u) async {
    baseUrl = u.trim();
    (await SharedPreferences.getInstance()).setString('baseUrl', baseUrl);
    _build();
  }

  Future<void> setToken(String? t) async {
    token = t;
    if (t == null) {
      await _sec.delete(key: 'token');
    } else {
      await _sec.write(key: 'token', value: t);
    }
  }

  Future<String?> readSecure(String k) => _sec.read(key: k);
  Future<void> writeSecure(String k, String? v) =>
      v == null ? _sec.delete(key: k) : _sec.write(key: k, value: v);

  /// آدرس کامل رسانه (نسبی یا مطلق).
  String abs(String url) {
    if (url.startsWith('http')) return url;
    var u = url.startsWith('/') ? url : '/$url';
    if (u.startsWith('/media')) u = '/api$u';
    return '$_root$u';
  }

  Map<String, String> get authHeaders => {if (token != null) 'Authorization': 'Bearer $token'};

  Future<dynamic> _req(String method, String path,
      {Map<String, dynamic>? q, dynamic body}) async {
    try {
      final r = await dio.request(path,
          queryParameters: q, data: body, options: Options(method: method));
      return r.data;
    } on DioException catch (e) {
      final s = e.response?.statusCode ?? 0;
      var code = 'network';
      final d = e.response?.data;
      if (d is Map && d['error'] != null) {
        code = '${d['error']}';
      } else if (s != 0) {
        code = 'http_$s';
      }
      if (s == 401 && code != 'wrong_password') onUnauthorized?.call();
      if (s == 403 && code == 'account_disabled') onDisabled?.call();
      throw ApiError(code, s);
    }
  }

  Future<dynamic> getAny(String p, {Map<String, dynamic>? q}) => _req('GET', p, q: q);
  Future<Map<String, dynamic>> get(String p, {Map<String, dynamic>? q}) async =>
      Map<String, dynamic>.from(await _req('GET', p, q: q) as Map);
  Future<Map<String, dynamic>> post(String p, {dynamic body, Map<String, dynamic>? q}) async =>
      Map<String, dynamic>.from(await _req('POST', p, body: body, q: q) as Map);
  Future<Map<String, dynamic>> put(String p, {dynamic body}) async =>
      Map<String, dynamic>.from(await _req('PUT', p, body: body) as Map);
  Future<Map<String, dynamic>> patch(String p, {dynamic body}) async =>
      Map<String, dynamic>.from(await _req('PATCH', p, body: body) as Map);
  Future<Map<String, dynamic>> delete(String p) async =>
      Map<String, dynamic>.from(await _req('DELETE', p) as Map);
}

Map<String, dynamic> sq(String? studentId, [Map<String, dynamic>? extra]) =>
    {if (studentId != null) 'student': studentId, ...?extra};
