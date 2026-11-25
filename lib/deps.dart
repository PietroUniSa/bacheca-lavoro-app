import 'package:http/http.dart' as http;

import 'config.dart' as app_config;
import 'core/api_client.dart';
import 'core/token_store.dart';
import 'services/cv_opener.dart';
import 'services/file_picker_cv_picker.dart';
import 'services/cv_picker.dart';
import 'services/temp_file_cv_opener.dart';

class AppDeps {
  factory AppDeps.production() => AppDeps(
        apiBaseUrl: app_config.apiBaseUrl,
        tokenStore: SharedPreferencesTokenStore(),
        cvPicker: FilePickerCvPicker(),
        cvOpener: TempFileCvOpener(),
      );

  AppDeps({
    required this.apiBaseUrl,
    required this.tokenStore,
    required this.cvPicker,
    required this.cvOpener,
    http.Client? httpClient,
  }) : apiClient = ApiClient(
          baseUrl: apiBaseUrl,
          tokenStore: tokenStore,
          client: httpClient,
        );

  final String apiBaseUrl;
  final ApiClient apiClient;
  final TokenStore tokenStore;
  final CvPicker cvPicker;
  final CvOpener cvOpener;
}
