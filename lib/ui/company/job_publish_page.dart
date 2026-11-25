import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_exception.dart';
import '../../core/form_validators.dart';
import '../../data/jobs_api.dart';

class JobPublishPage extends StatefulWidget {
  const JobPublishPage({super.key, required this.jobsApi});

  final JobsApi jobsApi;

  @override
  State<JobPublishPage> createState() => _JobPublishPageState();
}

class _JobPublishPageState extends State<JobPublishPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  ApiException? _apiError;
  bool _isSubmitting = false;

  void _clearApiError() {
    if (_apiError != null) setState(() => _apiError = null);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _apiError = null;
    });
    try {
      await widget.jobsApi.createJob(
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
      );
      if (mounted) context.pop(true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _apiError = error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Nuovo annuncio')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                key: const ValueKey('job_title_field'),
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titolo'),
                onChanged: (_) => _clearApiError(),
                validator: (value) =>
                    _apiError?.fields?['title'] ?? validateJobTitle(value),
              ),
              TextFormField(
                key: const ValueKey('job_description_field'),
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descrizione'),
                minLines: 4,
                maxLines: 8,
                onChanged: (_) => _clearApiError(),
                validator: (value) =>
                    _apiError?.fields?['description'] ??
                    validateJobDescription(value),
              ),
              TextFormField(
                key: const ValueKey('job_location_field'),
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Località'),
                onChanged: (_) => _clearApiError(),
                validator: (value) =>
                    _apiError?.fields?['location'] ??
                    validateJobLocation(value),
              ),
              if (_apiError != null && _apiError!.code != 'VALIDATION_ERROR')
                Text(
                  _apiError!.message,
                  key: const ValueKey('job_publish_error'),
                ),
              FilledButton(
                key: const ValueKey('job_publish'),
                onPressed: _isSubmitting ? null : _submit,
                child: const Text('Pubblica'),
              ),
            ],
          ),
        ),
      );
}
