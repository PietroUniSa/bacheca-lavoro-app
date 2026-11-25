import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_exception.dart';
import '../../core/form_validators.dart';
import '../../data/auth_api.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.authApi});

  final AuthApi authApi;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  ApiException? _apiError;
  bool _isSubmitting = false;

  void _clearApiError() {
    if (_apiError != null) setState(() => _apiError = null);
  }

  @override
  void dispose() {
    _nameController.dispose();
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
      await widget.authApi.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account creato')),
      );
      final email = Uri.encodeQueryComponent(
        _emailController.text.trim().toLowerCase(),
      );
      context.go('/company/login?email=$email');
    } on ApiException catch (error) {
      if (mounted) setState(() => _apiError = error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Crea account')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                key: const ValueKey('register_name'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Ragione sociale'),
                onChanged: (_) => _clearApiError(),
                validator: (value) =>
                    _apiError?.fields?['name'] ?? validateCompanyName(value),
              ),
              TextFormField(
                key: const ValueKey('register_email'),
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => _clearApiError(),
                validator: (value) =>
                    _apiError?.fields?['email'] ?? validateEmail(value),
              ),
              TextFormField(
                key: const ValueKey('register_password'),
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
                  key: const ValueKey('register_error'),
                ),
              FilledButton(
                key: const ValueKey('register_submit'),
                onPressed: _isSubmitting ? null : _submit,
                child: const Text('Crea account'),
              ),
            ],
          ),
        ),
      );
}
