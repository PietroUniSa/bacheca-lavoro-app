import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api_exception.dart';
import '../../data/applications_api.dart';
import '../../data/models.dart';

class JobApplicationsPage extends StatefulWidget {
  const JobApplicationsPage({
    super.key,
    required this.jobId,
    required this.applicationsApi,
  });

  final int jobId;
  final ApplicationsApi applicationsApi;

  @override
  State<JobApplicationsPage> createState() => _JobApplicationsPageState();
}

class _JobApplicationsPageState extends State<JobApplicationsPage> {
  late Future<List<JobApplication>> _applications;

  @override
  void initState() {
    super.initState();
    _applications = widget.applicationsApi.listForJob(widget.jobId);
  }

  void _retry() {
    setState(() {
      _applications = widget.applicationsApi.listForJob(widget.jobId);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: ModalRoute.of(context)?.isCurrent ?? true,
          title: const Text('Candidature'),
        ),
        body: FutureBuilder<List<JobApplication>>(
          future: _applications,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _error(snapshot.error!);
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _list(snapshot.data!);
          },
        ),
      );

  Widget _error(Object error) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error is ApiException ? error.message : error.toString(),
              key: const ValueKey('applications_error'),
            ),
            FilledButton(
              key: const ValueKey('retry_button'),
              onPressed: _retry,
              child: const Text('Riprova'),
            ),
          ],
        ),
      );

  Widget _list(List<JobApplication> applications) {
    if (applications.isEmpty) {
      return const Center(
        child: Text(
          'Ancora nessuna candidatura',
          key: ValueKey('applications_empty'),
        ),
      );
    }
    return ListView.builder(
      key: const ValueKey('applications_list'),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final application = applications[index];
        return ListTile(
          title: Text('${application.firstName} ${application.lastName}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(application.email),
              Text(DateFormat('dd/MM/yyyy').format(application.createdAt)),
            ],
          ),
          isThreeLine: true,
          onTap: () => context.push('/company/applications/${application.id}'),
        );
      },
    );
  }
}
