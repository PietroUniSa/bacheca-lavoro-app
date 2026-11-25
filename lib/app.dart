import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/applications_api.dart';
import 'data/auth_api.dart';
import 'data/jobs_api.dart';
import 'deps.dart';
import 'router.dart';
import 'state/session.dart';

class BachecaApp extends StatefulWidget {
  const BachecaApp({super.key, required this.deps});

  final AppDeps deps;

  @override
  State<BachecaApp> createState() => _BachecaAppState();
}

class _BachecaAppState extends State<BachecaApp> {
  late final Session _session;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _session = Session(
      apiClient: widget.deps.apiClient,
      tokenStore: widget.deps.tokenStore,
    );
    _router = createAppRouter(
      _session,
      JobsApi(widget.deps.apiClient),
      AuthApi(widget.deps.apiClient),
      ApplicationsApi(widget.deps.apiClient),
      widget.deps.cvPicker,
      widget.deps.cvOpener,
    );
    unawaited(_session.restore());
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routerConfig: _router,
      );

  @override
  void dispose() {
    _router.dispose();
    _session.dispose();
    super.dispose();
  }
}
