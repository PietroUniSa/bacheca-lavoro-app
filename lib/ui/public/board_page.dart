import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api_exception.dart';
import '../../data/jobs_api.dart';
import '../../data/models.dart';

class BoardPage extends StatefulWidget {
  const BoardPage({super.key, required this.jobsApi});

  final JobsApi jobsApi;

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  late Future<List<Job>> _jobs;

  @override
  void initState() {
    super.initState();
    _jobs = widget.jobsApi.listJobs();
  }

  void _retry() {
    setState(() {
      _jobs = widget.jobsApi.listJobs();
    });
  }

  Future<void> _refresh() {
    final next = widget.jobsApi.listJobs();
    setState(() {
      _jobs = next;
    });
    // FutureBuilder renders the failed future in the page error state.
    return next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Bacheca Lavoro'),
          actions: [
            IconButton(
              key: const ValueKey('company_area_button'),
              tooltip: 'Area aziende',
              icon: const Icon(Icons.business),
              onPressed: () => context.push('/company'),
            ),
          ],
        ),
        body: FutureBuilder<List<Job>>(
          future: _jobs,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _error(snapshot.error!);
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _jobList(snapshot.data!);
          },
        ),
      );

  Widget _error(Object error) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage(error),
              key: const ValueKey('board_error'),
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

  Widget _jobList(List<Job> jobs) => RefreshIndicator(
        key: const ValueKey('board_refresh'),
        onRefresh: _refresh,
        child: jobs.isEmpty
            ? ListView(
                key: const ValueKey('board_list'),
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 360,
                    child: Center(
                      child: Text(
                        'Nessun annuncio pubblicato',
                        key: ValueKey('board_empty'),
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                key: const ValueKey('board_list'),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: jobs.length,
                itemBuilder: (context, index) => _jobCard(context, jobs[index]),
              ),
      );

  Widget _jobCard(BuildContext context, Job job) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: InkWell(
          onTap: () => context.push('/jobs/${job.id}'),
          child: ListTile(
            title: Text(job.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.companyName),
                Text(DateFormat('dd/MM/yyyy').format(job.createdAt.toLocal())),
              ],
            ),
            isThreeLine: true,
          ),
        ),
      );

  String _errorMessage(Object error) =>
      error is ApiException ? error.message : error.toString();
}
