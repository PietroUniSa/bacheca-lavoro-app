import 'package:http/http.dart' as http;

import '../core/api_client.dart';
import 'models.dart';

class ApplicationsApi {
  const ApplicationsApi(this._client);

  final ApiClient _client;

  Future<List<JobApplication>> listForJob(int jobId) async {
    final response = await _client.get('/api/jobs/$jobId/applications');
    if (response is! Map<String, dynamic> || response['items'] is! List) {
      throw const FormatException('Elenco candidature non valido');
    }
    final items = response['items'] as List<dynamic>;
    return items.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Candidatura non valida');
      }
      return JobApplication.fromJson(item);
    }).toList(growable: false);
  }

  Future<JobApplication> getApplication(int id) async {
    final response = await _client.get('/api/applications/$id');
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Dettaglio candidatura non valido');
    }
    return JobApplication.fromJson(response);
  }

  Future<List<int>> getCvBytes(int id) =>
      _client.getBytes('/api/applications/$id/cv');

  Future<JobApplication> apply({
    required int jobId,
    required String firstName,
    required String lastName,
    required String email,
    required String cvName,
    required List<int> cvBytes,
  }) async {
    final response = await _client.postMultipart(
      '/api/jobs/$jobId/applications',
      fields: {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
      },
      file: http.MultipartFile.fromBytes(
        'cv',
        cvBytes,
        filename: cvName,
      ),
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Risposta candidatura non valida');
    }
    return JobApplication.fromJson(response);
  }
}
