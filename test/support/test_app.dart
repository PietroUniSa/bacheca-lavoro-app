import 'package:bacheca_app/app.dart';
import 'package:bacheca_app/core/token_store.dart';
import 'package:bacheca_app/deps.dart';
import 'package:bacheca_app/services/cv_opener.dart';
import 'package:bacheca_app/services/cv_picker.dart';
import 'package:http/http.dart' as http;

BachecaApp testApp(
  http.Client client, {
  CvPicker? cvPicker,
  CvOpener? cvOpener,
}) =>
    BachecaApp(
      deps: AppDeps(
        apiBaseUrl: 'http://api.example.test',
        tokenStore: InMemoryTokenStore(),
        cvPicker: cvPicker ?? _TestCvPicker(),
        cvOpener: cvOpener ?? _TestCvOpener(),
        httpClient: client,
      ),
    );

class _TestCvPicker implements CvPicker {
  @override
  Future<PickedCv?> pick() async => null;
}

class _TestCvOpener implements CvOpener {
  @override
  Future<void> open(List<int> bytes, String fileName) async {}
}
