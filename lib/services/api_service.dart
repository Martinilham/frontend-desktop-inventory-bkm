import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({String? baseUrl}) : _baseUrl = baseUrl ?? 'http://192.168.3.13:3000';

  final String _baseUrl;

  String get baseUrl => _baseUrl;
  SharedPreferences? _prefs;
  String? _token;
  String _deviceInfo = 'unknown-device';

  String? get token => _token;

  String _formatApiDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs!.getString('auth_token');
    _deviceInfo = await _loadDeviceInfo();
  }

  Future<String> _loadDeviceInfo() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isWindows) {
        final info = await plugin.windowsInfo;
        return 'Windows ${info.computerName} ${info.productName}';
      }
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return 'Android ${info.manufacturer} ${info.model}';
      }
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return 'iOS ${info.name} ${info.model}';
      }
      if (Platform.isMacOS) {
        final info = await plugin.macOsInfo;
        return 'macOS ${info.computerName} ${info.model}';
      }
      if (Platform.isLinux) {
        final info = await plugin.linuxInfo;
        return 'Linux ${info.prettyName}';
      }
    } catch (_) {}
    return '${Platform.operatingSystem} device';
  }

  Map<String, String> get _deviceHeaders => {
        'X-Device-Info': _deviceInfo,
      };

  Future<void> saveToken(String token) async {
    _prefs ??= await SharedPreferences.getInstance();
    _token = token;
    await _prefs!.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _prefs ??= await SharedPreferences.getInstance();
    _token = null;
    await _prefs!.remove('auth_token');
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json', ..._deviceHeaders},
      body: jsonEncode({'username': username, 'password': password}),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Login gagal');
    }

    await saveToken(body['token'] as String);
    return body;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _authorizedGet('/api/auth/me');
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal memuat profil');
    }
    return body;
  }

  Future<List<dynamic>> listUsers() async {
    final response = await _authorizedGet('/api/auth/users');
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal memuat pengguna');
    }
    return List<dynamic>.from(body['users'] ?? []);
  }

  Future<Map<String, dynamic>> createUser({
    required String username,
    required String phoneNumber,
    required String password,
    required String role,
    required bool active,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/register'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
        ..._deviceHeaders,
      },
      body: jsonEncode({
        'username': username,
        'phoneNumber': phoneNumber,
        'password': password,
        'role': role,
        'active': active,
      }),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal membuat akun');
    }

    return body;
  }

  Future<Map<String, dynamic>> updateUser(String id,
      {required String role,
      required bool active,
      required String phoneNumber}) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/auth/users/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
        ..._deviceHeaders,
      },
      body: jsonEncode(
          {'role': role, 'active': active, 'phoneNumber': phoneNumber}),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal memperbarui akun');
    }

    return body;
  }

  Future<Map<String, dynamic>> deleteUser(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/auth/users/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
        ..._deviceHeaders,
      },
    );

    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal menghapus akun');
    }

    return body;
  }

  Future<List<dynamic>> listAudit() async {
    final response = await _authorizedGet('/api/auth/audit');
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal memuat audit');
    }
    return List<dynamic>.from(body['logs'] ?? []);
  }

  Future<List<dynamic>> listDisposals() async {
    final response = await _authorizedGet('/api/disposals');
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal memuat disposal');
    }
    return List<dynamic>.from(body['disposals'] ?? []);
  }

  Future<List<dynamic>> listGrabMerch() async {
    final response = await _authorizedGet('/api/grabmerch');
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal memuat GrabMerch');
    }
    return List<dynamic>.from(body['items'] ?? []);
  }

  Future<List<dynamic>> listAbsenceDocuments() async {
    final response = await _authorizedGet('/api/absence-documents');
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal memuat dokumentasi absensi');
    }
    return List<dynamic>.from(body['items'] ?? []);
  }

  Future<List<dynamic>> listReadData() async {
    final response = await _authorizedGet('/api/read-data');
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal memuat data terbaca');
    }
    return List<dynamic>.from(body['items'] ?? []);
  }

  Future<Map<String, dynamic>> getDailyProductAnalysis() async {
    final response = await _authorizedGet('/api/analysis/daily-products');
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal memuat analisa produk harian');
    }
    return Map<String, dynamic>.from(body);
  }

  Future<List<dynamic>> listFiles() async {
    final response = await _authorizedGet('/api/files/records');
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal memuat daftar file');
    }
    return List<dynamic>.from(body['files'] ?? []);
  }

  Future<Map<String, dynamic>> getDailyWorkerDashboard({
    required String monthKey,
    String? dayKey,
  }) async {
    final query = <String, String>{'month': monthKey};
    if (dayKey != null && dayKey.isNotEmpty) {
      query['day'] = dayKey;
    }

    final response = await _authorizedGet(
      '/api/daily-worker/dashboard?${Uri(queryParameters: query).query}',
    );
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal memuat daily worker');
    }
    return Map<String, dynamic>.from(body);
  }

  Future<List<dynamic>> listDailyWorkerTemplates() async {
    final response = await _authorizedGet('/api/daily-worker/templates');
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal memuat template daily worker');
    }
    return List<dynamic>.from(body['templates'] ?? []);
  }

  Future<Map<String, dynamic>> createDailyWorkerTemplate(
    Map<String, dynamic> payload,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/daily-worker/templates'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
        ..._deviceHeaders,
      },
      body: jsonEncode(payload),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal membuat template daily worker');
    }
    return Map<String, dynamic>.from(body['template'] ?? {});
  }

  Future<Map<String, dynamic>> applyDailyWorkerTemplate(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/daily-worker/templates/$id/apply'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
        ..._deviceHeaders,
      },
      body: jsonEncode(payload),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal memakai template daily worker');
    }
    return Map<String, dynamic>.from(body['task'] ?? {});
  }

  Future<void> deleteDailyWorkerTemplate(String id) async {
    final response = await _authorizedDelete('/api/daily-worker/templates/$id');
    final body = _decodeResponseBody(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal menghapus template daily worker');
    }
  }

  Future<List<dynamic>> listDailyWorkerTasks({
    required String monthKey,
    String? dayKey,
  }) async {
    final query = <String, String>{'month': monthKey};
    if (dayKey != null && dayKey.isNotEmpty) {
      query['day'] = dayKey;
    }
    final response = await _authorizedGet(
      '/api/daily-worker/tasks?${Uri(queryParameters: query).query}',
    );
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal memuat task harian');
    }
    return List<dynamic>.from(body['tasks'] ?? []);
  }

  Future<Map<String, dynamic>> createDailyWorkerTask(
    Map<String, dynamic> payload,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/daily-worker/tasks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
        ..._deviceHeaders,
      },
      body: jsonEncode(payload),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal membuat task harian');
    }
    return Map<String, dynamic>.from(body['task'] ?? {});
  }

  Future<Map<String, dynamic>> updateDailyWorkerTask(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/daily-worker/tasks/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
        ..._deviceHeaders,
      },
      body: jsonEncode(payload),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal memperbarui task harian');
    }
    return Map<String, dynamic>.from(body['task'] ?? {});
  }

  Future<Map<String, dynamic>> changeDailyWorkerTaskStatus(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/api/daily-worker/tasks/$id/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
        ..._deviceHeaders,
      },
      body: jsonEncode(payload),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal mengubah status task');
    }
    return Map<String, dynamic>.from(body['task'] ?? {});
  }

  Future<void> deleteDailyWorkerTask(String id) async {
    final response = await _authorizedDelete('/api/daily-worker/tasks/$id');
    final body = _decodeResponseBody(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal menghapus task harian');
    }
  }

  Future<void> deleteDisposal(String id) async {
    final response = await _authorizedDelete('/api/disposals/$id');
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Hapus disposal gagal');
    }
  }

  Future<Map<String, dynamic>> updateDisposal(
    String id, {
    required String division,
    required DateTime date,
    String? journal,
    List<String> photoPaths = const [],
    String? scannedPdfPath,
    Map<String, int> photoRotations = const {},
    List<String> removePhotos = const [],
  }) async {
    Future<http.StreamedResponse> sendUpdate(String method, String path) async {
      final request =
          http.MultipartRequest(method, Uri.parse('$_baseUrl$path'));
      request.headers['Authorization'] = 'Bearer $_token';
      request.headers.addAll(_deviceHeaders);
      request.fields['division'] = division;
      request.fields['date'] = _formatApiDate(date);
      request.fields['journal'] = journal?.trim() ?? '';
      if (photoRotations.isNotEmpty) {
        request.fields['photoRotations'] = jsonEncode(photoRotations);
      }
      if (removePhotos.isNotEmpty) {
        request.fields['removePhotos'] = jsonEncode(removePhotos);
      }

      for (final path in photoPaths) {
        request.files.add(await http.MultipartFile.fromPath('photos', path));
      }

      if (scannedPdfPath != null && scannedPdfPath.isNotEmpty) {
        request.files.add(
            await http.MultipartFile.fromPath('scannedPdf', scannedPdfPath));
      }

      return request.send();
    }

    var streamedResponse =
        await sendUpdate('POST', '/api/disposals/$id/update');
    var body = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 404) {
      streamedResponse = await sendUpdate('PUT', '/api/disposals/$id');
      body = await streamedResponse.stream.bytesToString();
    }

    if (streamedResponse.statusCode == 401 ||
        streamedResponse.statusCode == 403) {
      await clearToken();
      throw AuthException('Sesi telah berakhir. Silakan login kembali.');
    }

    final decodedBody = _decodeResponseBody(body);
    if (streamedResponse.statusCode >= 400) {
      throw Exception(decodedBody['message'] ??
          'Update disposal gagal (${streamedResponse.statusCode})');
    }

    return Map<String, dynamic>.from(decodedBody['disposal'] ?? {});
  }

  Map<String, dynamic> _decodeResponseBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'message': decoded.toString()};
    } catch (_) {
      final preview = body
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .trim();
      return {
        'message': preview.isEmpty
            ? 'Backend tidak mengembalikan JSON.'
            : 'Backend mengembalikan respons non-JSON: $preview'
      };
    }
  }

  Future<Map<String, dynamic>> uploadDisposal({
    required String division,
    required DateTime date,
    required List<String> photoPaths,
    String? scannedPdfPath,
    String? journal,
  }) async {
    final request = http.MultipartRequest(
        'POST', Uri.parse('$_baseUrl/api/disposals/upload'));
    request.headers['Authorization'] = 'Bearer $_token';
    request.headers.addAll(_deviceHeaders);
    request.fields['division'] = division;
    request.fields['date'] = _formatApiDate(date);
    if (journal != null && journal.trim().isNotEmpty) {
      request.fields['journal'] = journal.trim();
    }

    for (final path in photoPaths) {
      request.files.add(await http.MultipartFile.fromPath('photos', path));
    }

    if (scannedPdfPath != null && scannedPdfPath.isNotEmpty) {
      request.files
          .add(await http.MultipartFile.fromPath('scannedPdf', scannedPdfPath));
    }

    final streamedResponse = await request.send();
    final body = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 401 ||
        streamedResponse.statusCode == 403) {
      await clearToken();
      throw AuthException('Sesi telah berakhir. Silakan login kembali.');
    }

    final decodedBody = jsonDecode(body);
    if (streamedResponse.statusCode >= 400) {
      throw Exception(decodedBody['message'] ?? 'Upload disposal gagal');
    }

    return decodedBody;
  }

  Future<Map<String, dynamic>> uploadAbsenceDocument({
    required String employeeName,
    required String documentType,
    required String proofPhotoPath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/absence-documents/upload'),
    );
    request.headers['Authorization'] = 'Bearer $_token';
    request.headers.addAll(_deviceHeaders);
    request.fields['employeeName'] = employeeName;
    request.fields['documentType'] = documentType;
    request.files.add(
      await http.MultipartFile.fromPath('proofPhoto', proofPhotoPath),
    );

    final streamedResponse = await request.send();
    final body = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 401 ||
        streamedResponse.statusCode == 403) {
      await clearToken();
      throw AuthException('Sesi telah berakhir. Silakan login kembali.');
    }

    final decodedBody = jsonDecode(body);
    if (streamedResponse.statusCode >= 400) {
      throw Exception(
          decodedBody['message'] ?? 'Upload dokumentasi absensi gagal');
    }

    return decodedBody;
  }

  Future<Map<String, dynamic>> updateAbsenceDocument(
    String id, {
    required String employeeName,
    required String documentType,
    String? proofPhotoPath,
  }) async {
    Future<http.StreamedResponse> sendUpdate(String method, String path) async {
      final request =
          http.MultipartRequest(method, Uri.parse('$_baseUrl$path'));
      request.headers['Authorization'] = 'Bearer $_token';
      request.headers.addAll(_deviceHeaders);
      request.fields['employeeName'] = employeeName;
      request.fields['documentType'] = documentType;
      if (proofPhotoPath != null && proofPhotoPath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('proofPhoto', proofPhotoPath),
        );
      }
      return request.send();
    }

    var streamedResponse =
        await sendUpdate('POST', '/api/absence-documents/$id/update');
    var body = await streamedResponse.stream.bytesToString();
    if (streamedResponse.statusCode == 404) {
      streamedResponse = await sendUpdate('PUT', '/api/absence-documents/$id');
      body = await streamedResponse.stream.bytesToString();
    }
    final decodedBody = _decodeResponseBody(body);
    if (streamedResponse.statusCode >= 400) {
      throw Exception(decodedBody['message'] ?? 'Update absensi gagal');
    }
    return Map<String, dynamic>.from(decodedBody['item'] ?? {});
  }

  Future<void> deleteAbsenceDocument(String id) async {
    final response = await _authorizedDelete('/api/absence-documents/$id');
    final body = _decodeResponseBody(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Hapus absensi gagal');
    }
  }

  Future<http.Response> _authorizedGet(String path) async {
    if (_token == null || _token!.isEmpty) {
      await clearToken();
      throw AuthException('Sesi belum aktif. Silakan login kembali.');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
        ..._deviceHeaders,
      },
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await clearToken();
      throw AuthException('Sesi telah berakhir. Silakan login kembali.');
    }

    return response;
  }

  Future<http.Response> _authorizedDelete(String path) async {
    if (_token == null || _token!.isEmpty) {
      await clearToken();
      throw AuthException('Sesi belum aktif. Silakan login kembali.');
    }

    final response = await http.delete(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
        ..._deviceHeaders,
      },
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await clearToken();
      throw AuthException('Sesi telah berakhir. Silakan login kembali.');
    }

    return response;
  }

}
