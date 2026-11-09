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
  ApiService({String? baseUrl})
      : _baseUrl = baseUrl ?? 'http://192.168.3.13:3000';

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
        'X-Client-Platform': 'desktop',
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

  Future<List<dynamic>> listSozaiProductionMaster() async {
    final response = await _authorizedGet('/api/sozai-production-master');
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal memuat master sozai');
    }
    return List<dynamic>.from(body['items'] ?? []);
  }

  Future<Map<String, dynamic>> createSozaiProductionMaster(
    Map<String, dynamic> payload,
  ) async {
    final authorization = await _authorizationHeader();
    final response = await http.post(
      Uri.parse('$_baseUrl/api/sozai-production-master'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authorization,
        ..._deviceHeaders,
      },
      body: jsonEncode(payload),
    );
    if (response.statusCode == 401 || response.statusCode == 403) {
      await clearToken();
      throw AuthException('Sesi telah berakhir. Silakan login kembali.');
    }
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal menambahkan master sozai');
    }
    return Map<String, dynamic>.from(body['item'] ?? {});
  }

  Future<Map<String, dynamic>> updateSozaiProductionMaster(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final authorization = await _authorizationHeader();
    final response = await http.put(
      Uri.parse('$_baseUrl/api/sozai-production-master/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authorization,
        ..._deviceHeaders,
      },
      body: jsonEncode(payload),
    );
    if (response.statusCode == 401 || response.statusCode == 403) {
      await clearToken();
      throw AuthException('Sesi telah berakhir. Silakan login kembali.');
    }
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal memperbarui master sozai');
    }
    return Map<String, dynamic>.from(body['item'] ?? {});
  }

  Future<void> deleteSozaiProductionMaster(String id) async {
    final response =
        await _authorizedDelete('/api/sozai-production-master/$id');
    final body = _decodeResponseBody(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal menghapus master sozai');
    }
  }

  Future<Map<String, dynamic>> importSozaiProductionMaster(
      String filePath) async {
    final authorization = await _authorizationHeader();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/sozai-production-master/import'),
    );
    request.headers.addAll({
      'Authorization': authorization,
      ..._deviceHeaders,
    });
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 401 || response.statusCode == 403) {
      await clearToken();
      throw AuthException('Sesi telah berakhir. Silakan login kembali.');
    }
    final body = _decodeResponseBody(response.body);
    if (response.statusCode >= 400) {
      final details = List<String>.from(body['details'] ?? const []);
      final message = body['message'] ?? 'Gagal mengimpor master sozai';
      throw Exception(
        details.isEmpty ? message : '$message\n${details.join('\n')}',
      );
    }
    return Map<String, dynamic>.from(body);
  }

  Future<List<dynamic>> listMonitorDevices() async {
    final response = await _authorizedGet('/api/monitor-devices');
    final body = _decodeResponseBody(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal memuat perangkat monitor');
    }
    return List<dynamic>.from(body['devices'] ?? []);
  }

  Future<Map<String, dynamic>> createMonitorDevice({
    required String name,
    required String ipAddress,
    String location = '',
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/monitor-devices'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
        ..._deviceHeaders,
      },
      body: jsonEncode(
          {'name': name, 'ipAddress': ipAddress, 'location': location}),
    );
    final body = _decodeResponseBody(response.body);
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AuthException(body['message'] ?? 'Akses ditolak');
    }
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal menambahkan perangkat');
    }
    return Map<String, dynamic>.from(body['device'] ?? {});
  }

  Future<void> deleteMonitorDevice(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/monitor-devices/$id'),
      headers: {'Authorization': 'Bearer $_token', ..._deviceHeaders},
    );
    final body = _decodeResponseBody(response.body);
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AuthException(body['message'] ?? 'Akses ditolak');
    }
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal menghapus perangkat');
    }
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

  Future<List<dynamic>> listFormPhotoDocuments() async {
    final response = await _authorizedGet('/api/form-photo-documents');
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal memuat form update customer');
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

  Future<Map<String, dynamic>> uploadReceiptAttachment({
    required List<String> filePaths,
    String name = '',
    String description = '',
    String documentDate = '',
    String fromLocation = '',
    String toLocation = '',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/files/upload-many'),
    );
    request.headers['Authorization'] = 'Bearer $_token';
    request.headers.addAll(_deviceHeaders);
    request.fields['folder'] = 'tanda-terima';
    request.fields['name'] = name.trim();
    request.fields['description'] = description.trim();
    request.fields['documentDate'] = documentDate;
    request.fields['fromLocation'] = fromLocation.trim();
    request.fields['toLocation'] = toLocation.trim();
    for (final filePath in filePaths) {
      request.files.add(await http.MultipartFile.fromPath('files', filePath));
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal mengunggah lampiran');
    }
    return Map<String, dynamic>.from(body);
  }

  Future<Map<String, dynamic>> updateReceiptAttachment({
    required String id,
    required String name,
    required String description,
    required String documentDate,
    required String fromLocation,
    required String toLocation,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/files/records/$id'),
      headers: {
        'Authorization': 'Bearer $_token',
        ..._deviceHeaders,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'documentDate': documentDate,
        'fromLocation': fromLocation,
        'toLocation': toLocation,
      }),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal mengubah lampiran');
    }
    return Map<String, dynamic>.from(body['file'] ?? {});
  }

  Future<void> deleteReceiptAttachment(String id) async {
    final response = await _authorizedDelete('/api/files/records/$id');
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal menghapus lampiran');
    }
  }

  Future<List<dynamic>> listInventoryDeadlines() async {
    final response = await _authorizedGet('/api/inventory-deadlines');
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal memuat deadline inventory');
    }
    return List<dynamic>.from(body['deadlines'] ?? []);
  }

  Future<Map<String, dynamic>> getInventoryTransactions() async {
    final response = await _authorizedGet('/api/inventory-transactions');
    final body = _decodeResponseBody(response.body);
    if (response.statusCode >= 400)
      throw Exception(body['message'] ?? 'Gagal memuat inventory');
    return Map<String, dynamic>.from(body);
  }

  Future<List<dynamic>> getInventoryItemTransactions(
      String itemNumber, String warehouse) async {
    final query = Uri(queryParameters: {
      'itemNumber': itemNumber,
      'warehouse': warehouse,
    }).query;
    final response = await _authorizedGet(
        '/api/inventory-transactions/item-details?$query');
    final body = _decodeResponseBody(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal memuat rincian transaksi item');
    }
    return List<dynamic>.from(body['transactions'] ?? []);
  }

  Future<Map<String, dynamic>> importInventorySnapshot(
      String endpoint, String fileName, List<Map<String, dynamic>> rows) async {
    final authorization = await _authorizationHeader();
    if (endpoint == 'upload') {
      Future<Map<String, dynamic>> postJson(
          String path, Map<String, dynamic> payload) async {
        final response = await http.post(
          Uri.parse('$_baseUrl/api/inventory-transactions/$path'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authorization,
            ..._deviceHeaders
          },
          body: jsonEncode(payload),
        );
        final body = _decodeResponseBody(response.body);
        if (response.statusCode >= 400) {
          throw Exception(body['message'] ?? 'Impor inventory gagal');
        }
        return Map<String, dynamic>.from(body);
      }

      final started =
          await postJson('upload/start', {'expectedRows': rows.length});
      final snapshotId = started['snapshotId']?.toString() ?? '';
      if (snapshotId.isEmpty)
        throw Exception('Backend tidak membuat snapshot impor.');
      const batchSize = 1000;
      try {
        for (var offset = 0; offset < rows.length; offset += batchSize) {
          final end = (offset + batchSize < rows.length)
              ? offset + batchSize
              : rows.length;
          await postJson('upload/chunk', {
            'snapshotId': snapshotId,
            'offset': offset,
            'fileName': fileName,
            'rows': rows.sublist(offset, end),
          });
        }
        return await postJson('upload/complete', {
          'snapshotId': snapshotId,
          'expectedRows': rows.length,
          'fileName': fileName,
        });
      } catch (_) {
        try {
          await postJson('upload/abort', {'snapshotId': snapshotId});
        } catch (_) {
          // Best effort cleanup if the connection is available again.
        }
        rethrow;
      }
    }
    final response = await http.post(
        Uri.parse('$_baseUrl/api/inventory-transactions/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authorization,
          ..._deviceHeaders
        },
        body: jsonEncode({'fileName': fileName, 'rows': rows}));
    final body = _decodeResponseBody(response.body);
    if (response.statusCode >= 400)
      throw Exception(body['message'] ?? 'Impor inventory gagal');
    return Map<String, dynamic>.from(body);
  }

  Future<Map<String, dynamic>> deleteInventorySnapshot(String dataset) async {
    if (dataset != 'baseline' && dataset != 'transactions') {
      throw ArgumentError.value(
          dataset, 'dataset', 'Dataset inventory tidak dikenal');
    }
    final response =
        await _authorizedDelete('/api/inventory-transactions/$dataset');
    final body = _decodeResponseBody(response.body);
    if (response.statusCode >= 400)
      throw Exception(body['message'] ?? 'Hapus data inventory gagal');
    return Map<String, dynamic>.from(body);
  }

  Future<Map<String, dynamic>> createInventoryDeadline(
    Map<String, dynamic> payload,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/inventory-deadlines'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
        ..._deviceHeaders,
      },
      body: jsonEncode(payload),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal membuat deadline inventory');
    }
    return Map<String, dynamic>.from(body['deadline'] ?? {});
  }

  Future<Map<String, dynamic>> updateInventoryDeadline(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/inventory-deadlines/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
        ..._deviceHeaders,
      },
      body: jsonEncode(payload),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(
          body['message'] ?? 'Gagal memperbarui deadline inventory');
    }
    return Map<String, dynamic>.from(body['deadline'] ?? {});
  }

  Future<void> deleteInventoryDeadline(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/inventory-deadlines/$id'),
      headers: {
        'Authorization': 'Bearer $_token',
        ..._deviceHeaders,
      },
    );
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal menghapus deadline inventory');
    }
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
      throw Exception(
          body['message'] ?? 'Gagal menghapus template daily worker');
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
    List<String> scannedPdfPaths = const [],
    Map<String, int> photoRotations = const {},
    List<String> removePhotos = const [],
    List<String> removeScannedPdfs = const [],
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
      if (removeScannedPdfs.isNotEmpty) {
        request.fields['removeScannedPdfs'] = jsonEncode(removeScannedPdfs);
      }

      for (final path in photoPaths) {
        request.files.add(await http.MultipartFile.fromPath('photos', path));
      }

      for (final pdfPath in scannedPdfPaths) {
        request.files
            .add(await http.MultipartFile.fromPath('scannedPdfs', pdfPath));
      }
      if (scannedPdfPath != null && scannedPdfPath.isNotEmpty) {
        request.files.add(
            await http.MultipartFile.fromPath('scannedPdfs', scannedPdfPath));
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

  Future<Map<String, dynamic>> deleteImportedDisposalJournals(
      List<String> ids) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/disposals/imports/delete'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
        ..._deviceHeaders
      },
      body: jsonEncode({'ids': ids}),
    );
    final body = _decodeResponseBody(response.body);
    if (response.statusCode == 401) {
      throw AuthException('Sesi berakhir. Silakan login kembali.');
    }
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Hapus impor gagal');
    }
    return body;
  }

  Future<Map<String, dynamic>> uploadDatedDisposalScan(
      String filePath, String division) async {
    final request = http.MultipartRequest(
        'POST', Uri.parse('$_baseUrl/api/disposals/scan-pdf'));
    request.headers
        .addAll({'Authorization': 'Bearer $_token', ..._deviceHeaders});
    request.fields['division'] = division;
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final response = await request.send();
    final body = _decodeResponseBody(await response.stream.bytesToString());
    if (response.statusCode == 401) {
      throw AuthException('Sesi berakhir. Silakan login kembali.');
    }
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Upload scan PDF gagal');
    }
    return body;
  }

  Future<Map<String, dynamic>> importDisposals(String filePath) async {
    final request = http.MultipartRequest(
        'POST', Uri.parse('$_baseUrl/api/disposals/import'));
    request.headers['Authorization'] = 'Bearer $_token';
    request.headers.addAll(_deviceHeaders);
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final response = await request.send();
    final body = _decodeResponseBody(await response.stream.bytesToString());
    if (response.statusCode == 401) {
      throw AuthException('Sesi telah berakhir. Silakan login kembali.');
    }
    if (response.statusCode >= 400) {
      final details = List<dynamic>.from(body['details'] ?? []);
      throw Exception([
        body['message'] ?? 'Impor Excel gagal',
        ...details.map((item) => item.toString()),
      ].join('\n'));
    }
    return body;
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

  Future<String> _authorizationHeader() async {
    if (_token == null || _token!.isEmpty) {
      await clearToken();
      throw AuthException('Sesi belum aktif. Silakan login kembali.');
    }
    return 'Bearer $_token';
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
