import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api_exception.dart';
import '../../data/applications_api.dart';
import '../../data/models.dart';
import '../../services/cv_opener.dart';

class ApplicationDetailPage extends StatefulWidget {
  const ApplicationDetailPage({
    super.key,
    required this.applicationId,
    required this.applicationsApi,
    required this.cvOpener,
  });

  final int applicationId;
  final ApplicationsApi applicationsApi;
  final CvOpener cvOpener;

  @override
  State<ApplicationDetailPage> createState() => _ApplicationDetailPageState();
}

class _ApplicationDetailPageState extends State<ApplicationDetailPage> {
  late Future<JobApplication> _application;
  bool _isOpeningCv = false;

  @override
  void initState() {
    super.initState();
    _application = widget.applicationsApi.getApplication(widget.applicationId);
  }

  void _retry() {
    setState(() {
      _application =
          widget.applicationsApi.getApplication(widget.applicationId);
    });
  }

  Future<void> _openCv(JobApplication application) async {
    setState(() => _isOpeningCv = true);
    try {
      final bytes = await widget.applicationsApi.getCvBytes(
        widget.applicationId,
      );
      try {
        await widget.cvOpener.open(bytes, application.cvOriginalName);
      } on Exception {
        _showMessage('Nessuna app per aprire il PDF');
      }
    } on ApiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isOpeningCv = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: ModalRoute.of(context)?.isCurrent ?? true,
          title: const Text('Dettaglio candidatura'),
        ),
        body: FutureBuilder<JobApplication>(
          future: _application,
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
              error is ApiException ? error.message : error.toString(),
              key: const ValueKey('application_error'),
            ),
            FilledButton(
              key: const ValueKey('retry_button'),
              onPressed: _retry,
              child: const Text('Riprova'),
            ),
          ],
        ),
      );

  Widget _details(JobApplication application) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${application.firstName} ${application.lastName}',
            key: const ValueKey('application_name'),
          ),
          KeyedSubtree(
            key: const ValueKey('application_email'),
            child: Text(application.email),
          ),
          Text(
            DateFormat('dd/MM/yyyy').format(application.createdAt),
            key: const ValueKey('application_date'),
          ),
          Text(
            application.cvOriginalName,
            key: const ValueKey('application_cv_name'),
          ),
          FilledButton(
            key: const ValueKey('open_cv_button'),
            onPressed: _isOpeningCv ? null : () => _openCv(application),
            child: const Text('Apri curriculum'),
          ),
        ],
      );
}
