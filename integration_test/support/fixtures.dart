// Preparazione dei "punti di partenza" degli scenari direttamente via API,
// così ogni scenario è indipendente dagli altri (contratto: specs/04).
import 'dart:convert';

import 'package:http/http.dart' as http;

class Fixtures {
  Fixtures(this.base);
  final Uri base;

  Map<String, String> _json([String? token]) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> _post(
    String path,
    Object body, [
    String? token,
  ]) async {
    final r = await http.post(
      base.resolve(path),
      headers: _json(token),
      body: jsonEncode(body),
    );
    if (r.statusCode >= 300) {
      throw StateError('POST $path → ${r.statusCode} ${r.body}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// Registra l'azienda e restituisce il token di sessione.
  Future<String> companyWithSession(String email) async {
    await _post('/api/auth/register', {
      'name': 'Acme Srl',
      'email': email,
      'password': 'Password123',
    });
    final login = await _post('/api/auth/login', {
      'email': email,
      'password': 'Password123',
    });
    return login['token'] as String;
  }

  Future<int> job(String token, String title) async {
    final job = await _post(
        '/api/jobs',
        {
          'title': title,
          'description':
              'Cerchiamo uno sviluppatore Flutter junior per app mobile in un team agile.',
          'location': 'Napoli',
        },
        token);
    return job['id'] as int;
  }

  Future<void> application(int jobId, List<int> cv) async {
    final req = http.MultipartRequest(
      'POST',
      base.resolve('/api/jobs/$jobId/applications'),
    )
      ..fields.addAll({
        'firstName': 'Mario',
        'lastName': 'Rossi',
        'email': 'mario.rossi@example.com',
      })
      ..files.add(
        http.MultipartFile.fromBytes(
          'cv',
          cv,
          filename: 'cv_mario_rossi.pdf',
        ),
      );
    final r = await req.send();
    if (r.statusCode != 201) throw StateError('candidatura → ${r.statusCode}');
  }

  Future<List<dynamic>> applicationsOf(String token, int jobId) async {
    final r = await http.get(
      base.resolve('/api/jobs/$jobId/applications'),
      headers: _json(token),
    );
    return (jsonDecode(r.body) as Map<String, dynamic>)['items']
        as List<dynamic>;
  }

  Future<int> meStatus(String token) async => (await http.get(
        base.resolve('/api/me'),
        headers: _json(token),
      ))
          .statusCode;

  Future<List<dynamic>> board() async {
    final r = await http.get(base.resolve('/api/jobs'));
    return (jsonDecode(r.body) as Map<String, dynamic>)['items']
        as List<dynamic>;
  }
}

/// PDF minimo valido (inizia con %PDF).
List<int> tinyPdf(String label) => utf8.encode(
      '%PDF-1.4\n'
      '1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n'
      '2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n'
      '3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 200 200]>>endobj\n'
      '% $label\ntrailer<</Root 1 0 R>>\n%%EOF\n',
    );
