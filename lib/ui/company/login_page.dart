import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_exception.dart';
import '../../core/form_validators.dart';
import '../../data/auth_api.dart';
import '../../state/session.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.authApi,
    required this.session,
    this.initialEmail = '',
  });

  final AuthApi authApi;
  final Session session;
  final String initialEmail;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  ApiException? _apiError;
  bool _isSubmitting = false;

  void _clearApiError() {
    if (_apiError != null) setState(() => _apiError = null);
  }

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _apiError = null;
    });
    try {
      final result = await widget.authApi.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await widget.session.login(
        token: result.token,
        company: result.company,
      );
      if (mounted) context.go('/company');
    } on ApiException catch (error) {
      if (mounted) setState(() => _apiError = error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Accedi')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                key: const ValueKey('login_email'),
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => _clearApiError(),
                validator: (value) =>
                    _apiError?.fields?['email'] ?? validateEmail(value),
              ),
              TextFormField(
                key: const ValueKey('login_password'),
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (_) => _clearApiError(),
                validator: (value) =>
                    _apiError?.fields?['password'] ?? validatePassword(value),
              ),
              if (_apiError != null && _apiError!.code != 'VALIDATION_ERROR')
                Text(
                  _apiError!.message,
                  key: const ValueKey('login_error'),
                ),
              FilledButton(
                key: const ValueKey('login_submit'),
                onPressed: _isSubmitting ? null : _submit,
                child: const Text('Accedi'),
              ),
              TextButton(
                key: const ValueKey('login_go_register'),
                onPressed: () => context.push('/company/register'),
                child: const Text('Registrati'),
              ),
            ],
          ),
        ),
      );
}
