import 'package:bacheca_app/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 11, 25);

  test('parses a public company response', () {
    // AC-NF-06
    final company = Company.fromJson({
      'id': 3,
      'name': 'Acme Srl',
      'email': 'hr@acme.it',
      'createdAt': createdAt.toIso8601String(),
    });

    expect(company.id, 3);
    expect(company.name, 'Acme Srl');
    expect(company.email, 'hr@acme.it');
    expect(company.createdAt, createdAt);
  });

  test('parses job and nullable location', () {
    // AC-NF-06
    final job = Job.fromJson({
      'id': 7,
      'title': 'Sviluppatore Flutter',
      'description': 'Descrizione annuncio',
      'location': null,
      'companyId': 3,
      'companyName': 'Acme Srl',
      'createdAt': createdAt.toIso8601String(),
    });

    expect(job.location, isNull);
    expect(job.companyId, 3);
    expect(job.createdAt, createdAt);
  });

  test('parses a company job and its application count', () {
    // AC-NF-06
    final job = MyJob.fromJson({
      'id': 7,
      'title': 'Sviluppatore Flutter',
      'description': 'Descrizione annuncio',
      'location': 'Napoli',
      'companyId': 3,
      'companyName': 'Acme Srl',
      'createdAt': createdAt.toIso8601String(),
      'applicationCount': 2,
    });

    expect(job, isA<Job>());
    expect(job.applicationCount, 2);
  });

  test('parses an application response', () {
    // AC-NF-06
    final application = JobApplication.fromJson({
      'id': 11,
      'jobId': 7,
      'firstName': 'Mario',
      'lastName': 'Rossi',
      'email': 'mario@example.com',
      'cvOriginalName': 'cv.pdf',
      'cvSize': 1234,
      'createdAt': createdAt.toIso8601String(),
    });

    expect(application.jobId, 7);
    expect(application.cvOriginalName, 'cv.pdf');
    expect(application.cvSize, 1234);
    expect(application.createdAt, createdAt);
  });
}
