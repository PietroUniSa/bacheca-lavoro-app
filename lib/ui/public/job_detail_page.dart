import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api_exception.dart';
import '../../data/jobs_api.dart';
import '../../data/models.dart';

class JobDetailPage extends StatefulWidget {
  const JobDetailPage({
    super.key,
    required this.jobsApi,
    required this.jobId,
  });

  final JobsApi jobsApi;
  final int jobId;

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  late Future<Job> _job;

  @override
  void initState() {
    super.initState();
    _job = widget.jobsApi.getJob(widget.jobId);
  }

  void _retry() {
    setState(() {
      _job = widget.jobsApi.getJob(widget.jobId);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Dettaglio annuncio')),
        body: FutureBuilder<Job>(
          future: _job,
          builder: (context, snapshot) {
            if (snapshot.hasError) return _error(snapshot.error!);
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _details(snapshot.data!);
          },
        ),
      );

  Widget _error(Object error) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage(error),
              key: const ValueKey('job_detail_error'),
              textAlign: TextAlign.center,
            ),
            FilledButton(
              key: const ValueKey('retry_button'),
              onPressed: _retry,
              child: const Text('Riprova'),
            ),
          ],
        ),
      );

  Widget _details(Job job) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KeyedSubtree(
              key: const ValueKey('job_detail_title'),
              child: Text(job.title),
            ),
            const SizedBox(height: 12),
            KeyedSubtree(
              key: const ValueKey('job_detail_company'),
              child: Text(job.companyName),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd/MM/yyyy').format(job.createdAt.toLocal()),
              key: const ValueKey('job_detail_date'),
            ),
            const SizedBox(height: 16),
            Text(job.description,
                key: const ValueKey('job_detail_description')),
            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('apply_button'),
              onPressed: () => context.push('/jobs/${job.id}/apply'),
              child: const Text('Candidati'),
            ),
          ],
        ),
      );

  String _errorMessage(Object error) =>
      error is ApiException ? error.message : error.toString();
}
