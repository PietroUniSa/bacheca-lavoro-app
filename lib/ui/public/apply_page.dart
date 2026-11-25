import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_exception.dart';
import '../../core/form_validators.dart';
import '../../data/applications_api.dart';
import '../../services/cv_picker.dart';

class ApplyPage extends StatefulWidget {
  const ApplyPage({
    super.key,
    required this.jobId,
    required this.applicationsApi,
    required this.cvPicker,
  });

  final int jobId;
  final ApplicationsApi applicationsApi;
  final CvPicker cvPicker;

  @override
  State<ApplyPage> createState() => _ApplyPageState();
}

class _ApplyPageState extends State<ApplyPage> {
  static const _fileError = 'Il curriculum deve essere un PDF (max 5 MB)';
  static const _maxCvBytes = 5 * 1024 * 1024;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  PickedCv? _cv;
  ApiException? _apiError;
  String? _cvError;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _clearApiError() {
    if (_apiError != null) setState(() => _apiError = null);
  }

  Future<void> _pickCv() async {
    final cv = await widget.cvPicker.pick();
    if (!mounted || cv == null) return;
    setState(() {
      _cv = cv;
      _cvError = _validateCv(cv);
      _apiError = null;
    });
  }

  String? _validateCv(PickedCv? cv) {
    if (cv == null || cv.bytes.isEmpty || cv.bytes.length > _maxCvBytes) {
      return _fileError;
    }
    if (cv.bytes.length < 4 ||
        cv.bytes[0] != 0x25 ||
        cv.bytes[1] != 0x50 ||
        cv.bytes[2] != 0x44 ||
        cv.bytes[3] != 0x46) {
      return _fileError;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final cvError = _validateCv(_cv);
    if (cvError != null) {
      setState(() => _cvError = cvError);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _apiError = null;
      _cvError = null;
    });
    try {
      await widget.applicationsApi.apply(
        jobId: widget.jobId,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        cvName: _cv!.name,
        cvBytes: _cv!.bytes,
      );
      if (mounted) setState(() => _isSubmitted = true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _apiError = error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => _isSubmitted
      ? _success(context)
      : Scaffold(
          appBar: AppBar(title: const Text('Candidati')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  key: const ValueKey('apply_first_name'),
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  onChanged: (_) => _clearApiError(),
                  validator: (value) =>
                      _apiError?.fields?['firstName'] ??
                      validateApplicantName(value, 'nome'),
                ),
                TextFormField(
                  key: const ValueKey('apply_last_name'),
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Cognome'),
                  onChanged: (_) => _clearApiError(),
                  validator: (value) =>
                      _apiError?.fields?['lastName'] ??
                      validateApplicantName(value, 'cognome'),
                ),
                TextFormField(
                  key: const ValueKey('apply_email'),
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => _clearApiError(),
                  validator: (value) =>
                      _apiError?.fields?['email'] ?? validateEmail(value),
                ),
                OutlinedButton(
                  key: const ValueKey('apply_pick_cv'),
                  onPressed: _isSubmitting ? null : _pickCv,
                  child: const Text('Allega curriculum (PDF)'),
                ),
                if (_cv != null)
                  KeyedSubtree(
                    key: const ValueKey('apply_cv_name'),
                    child: Text(_cv!.name),
                  ),
                if (_cvError != null)
                  Text(_cvError!, key: const ValueKey('apply_error')),
                if (_apiError != null && _apiError!.code != 'VALIDATION_ERROR')
                  Text(_apiError!.message, key: const ValueKey('apply_error')),
                FilledButton(
                  key: const ValueKey('apply_submit'),
                  onPressed: _isSubmitting ? null : _submit,
                  child: const Text('Invia candidatura'),
                ),
              ],
            ),
          ),
        );

  Widget _success(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Candidatura inviata!',
                key: ValueKey('apply_success'),
              ),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Torna alla bacheca'),
              ),
            ],
          ),
        ),
      );
}
