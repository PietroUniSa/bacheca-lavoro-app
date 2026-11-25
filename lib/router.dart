import 'package:go_router/go_router.dart';

import 'data/applications_api.dart';
import 'data/auth_api.dart';
import 'data/jobs_api.dart';
import 'services/cv_opener.dart';
import 'services/cv_picker.dart';
import 'state/session.dart';
import 'ui/company/application_detail_page.dart';
import 'ui/company/job_applications_page.dart';
import 'ui/company/job_publish_page.dart';
import 'ui/company/login_page.dart';
import 'ui/company/my_jobs_page.dart';
import 'ui/company/register_page.dart';
import 'ui/public/apply_page.dart';
import 'ui/public/board_page.dart';
import 'ui/public/job_detail_page.dart';

GoRouter createAppRouter(
  Session session,
  JobsApi jobsApi,
  AuthApi authApi,
  ApplicationsApi applicationsApi,
  CvPicker cvPicker,
  CvOpener cvOpener,
) =>
    GoRouter(
      initialLocation: '/',
      refreshListenable: session,
      redirect: (context, state) {
        if (!session.isInitialized) return null;
        if (_requiresSession(state.matchedLocation) &&
            !session.isAuthenticated) {
          return '/company/login';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: BoardPage(jobsApi: jobsApi),
          ),
        ),
        GoRoute(
          path: '/jobs/:id',
          builder: (context, state) => JobDetailPage(
            jobsApi: jobsApi,
            jobId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/jobs/:id/apply',
          builder: (context, state) => ApplyPage(
            jobId: int.parse(state.pathParameters['id']!),
            applicationsApi: applicationsApi,
            cvPicker: cvPicker,
          ),
        ),
        GoRoute(
          path: '/company/login',
          builder: (context, state) => LoginPage(
            authApi: authApi,
            session: session,
            initialEmail: state.uri.queryParameters['email'] ?? '',
          ),
        ),
        GoRoute(
          path: '/company/register',
          builder: (context, state) => RegisterPage(authApi: authApi),
        ),
        GoRoute(
          path: '/company',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: MyJobsPage(
              jobsApi: jobsApi,
              session: session,
            ),
          ),
        ),
        GoRoute(
          path: '/company/jobs/new',
          builder: (context, state) => JobPublishPage(jobsApi: jobsApi),
        ),
        GoRoute(
          path: '/company/jobs/:id',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: JobApplicationsPage(
              jobId: int.parse(state.pathParameters['id']!),
              applicationsApi: applicationsApi,
            ),
          ),
        ),
        GoRoute(
          path: '/company/applications/:id',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: ApplicationDetailPage(
              applicationId: int.parse(state.pathParameters['id']!),
              applicationsApi: applicationsApi,
              cvOpener: cvOpener,
            ),
          ),
        ),
      ],
    );

bool _requiresSession(String location) =>
    location == '/company' ||
    location.startsWith('/company/jobs/') ||
    location.startsWith('/company/applications/');
