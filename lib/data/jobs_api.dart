import '../core/api_client.dart';
import '../data/models.dart';

class JobsApi {
  const JobsApi(this._client);

  final ApiClient _client;

  Future<List<Job>> listJobs() async {
    final response = await _client.get('/api/jobs');
    if (response is! Map<String, dynamic> || response['items'] is! List) {
      throw const FormatException('Elenco annunci non valido');
    }

    final items = response['items'] as List<dynamic>;
    return items.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Annuncio non valido');
      }
      return Job.fromJson(item);
    }).toList(growable: false);
  }

  Future<Job> getJob(int id) async {
    final response = await _client.get('/api/jobs/$id');
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Dettaglio annuncio non valido');
    }
    return Job.fromJson(response);
  }

  Future<List<MyJob>> listMyJobs() async {
    final response = await _client.get('/api/companies/me/jobs');
    if (response is! Map<String, dynamic> || response['items'] is! List) {
      throw const FormatException('Elenco annunci aziendali non valido');
    }

    final items = response['items'] as List<dynamic>;
    return items.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Annuncio aziendale non valido');
      }
      return MyJob.fromJson(item);
    }).toList(growable: false);
  }

  Future<Job> createJob({
    required String title,
    required String description,
    String? location,
  }) async {
    final body = <String, String>{
      'title': title.trim(),
      'description': description.trim(),
    };
    final trimmedLocation = location?.trim() ?? '';
    if (trimmedLocation.isNotEmpty) body['location'] = trimmedLocation;

    final response = await _client.post('/api/jobs', body: body);
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Risposta pubblicazione non valida');
    }
    return Job.fromJson(response);
  }
}
