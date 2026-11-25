import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_exception.dart';
import '../../data/jobs_api.dart';
import '../../data/models.dart';
import '../../state/session.dart';

class MyJobsPage extends StatefulWidget {
  const MyJobsPage({
    super.key,
    required this.jobsApi,
    required this.session,
  });

  final JobsApi jobsApi;
  final Session session;

  @override
  State<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends State<MyJobsPage> {
  late Future<List<MyJob>> _jobs;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _jobs = widget.jobsApi.listMyJobs();
  }

  Future<void> _openNewJob() async {
    final created = await context.push<bool>('/company/jobs/new');
    if (created == true && mounted) {
      final jobs = widget.jobsApi.listMyJobs();
      setState(() {
        _jobs = jobs;
      });
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      await widget.session.logout();
      if (mounted) context.go('/');
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: ModalRoute.of(context)?.isCurrent ?? true,
          title: const Text(
            'I miei annunci',
            key: ValueKey('dashboard_title'),
          ),
          actions: [
            IconButton(
              key: const ValueKey('dashboard_board_button'),
              tooltip: 'Bacheca pubblica',
              icon: const Icon(Icons.public),
              onPressed: () => context.push('/'),
            ),
            IconButton(
              key: const ValueKey('logout_button'),
              tooltip: 'Esci',
              onPressed: _isLoggingOut ? null : _logout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: FutureBuilder<List<MyJob>>(
          future: _jobs,
          builder: (context, snapshot) {
            if (snapshot.hasError) return _error(snapshot.error!);
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _jobList(snapshot.data!);
          },
        ),
        floatingActionButton: FloatingActionButton(
          key: const ValueKey('new_job_button'),
          tooltip: 'Nuovo annuncio',
          onPressed: _openNewJob,
          child: const Icon(Icons.add),
        ),
      );

  Widget _error(Object error) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error is ApiException ? error.message : error.toString(),
              key: const ValueKey('my_jobs_error'),
              textAlign: TextAlign.center,
            ),
            FilledButton(
              key: const ValueKey('retry_button'),
              onPressed: () {
                setState(() {
                  _jobs = widget.jobsApi.listMyJobs();
                });
              },
              child: const Text('Riprova'),
            ),
          ],
        ),
      );

  Widget _jobList(List<MyJob> jobs) {
    if (jobs.isEmpty) {
      return const Center(
        child: Text(
          'Nessun annuncio pubblicato',
          key: ValueKey('my_jobs_empty'),
        ),
      );
    }
    return ListView.builder(
      key: const ValueKey('my_jobs_list'),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        final countLabel = job.applicationCount == 1
            ? '1 candidatura'
            : '${job.applicationCount} candidature';
        return ListTile(
          title: Text(job.title),
          subtitle: Text(countLabel),
          onTap: () => context.push('/company/jobs/${job.id}'),
        );
      },
    );
  }
}
