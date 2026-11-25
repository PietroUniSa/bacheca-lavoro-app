class Company {
  const Company({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String email;
  final DateTime createdAt;

  factory Company.fromJson(Map<String, dynamic> json) => Company(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class Job {
  const Job({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.companyId,
    required this.companyName,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String description;
  final String? location;
  final int companyId;
  final String companyName;
  final DateTime createdAt;

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        id: json['id'] as int,
        title: json['title'] as String,
        description: json['description'] as String,
        location: json['location'] as String?,
        companyId: json['companyId'] as int,
        companyName: json['companyName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class MyJob extends Job {
  const MyJob(
      {required super.id,
      required super.title,
      required super.description,
      required super.location,
      required super.companyId,
      required super.companyName,
      required super.createdAt,
      required this.applicationCount});

  final int applicationCount;

  factory MyJob.fromJson(Map<String, dynamic> json) {
    final job = Job.fromJson(json);
    return MyJob(
      id: job.id,
      title: job.title,
      description: job.description,
      location: job.location,
      companyId: job.companyId,
      companyName: job.companyName,
      createdAt: job.createdAt,
      applicationCount: json['applicationCount'] as int,
    );
  }
}

class JobApplication {
  const JobApplication({
    required this.id,
    required this.jobId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.cvOriginalName,
    required this.cvSize,
    required this.createdAt,
  });

  final int id;
  final int jobId;
  final String firstName;
  final String lastName;
  final String email;
  final String cvOriginalName;
  final int cvSize;
  final DateTime createdAt;

  factory JobApplication.fromJson(Map<String, dynamic> json) => JobApplication(
        id: json['id'] as int,
        jobId: json['jobId'] as int,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        email: json['email'] as String,
        cvOriginalName: json['cvOriginalName'] as String,
        cvSize: json['cvSize'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
