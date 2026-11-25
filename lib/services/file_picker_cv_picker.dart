import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'cv_picker.dart';

class FilePickerCvPicker implements CvPicker {
  @override
  Future<PickedCv?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final bytes = file.bytes ?? await _readFile(file.path);
    return PickedCv(name: file.name, bytes: bytes);
  }

  Future<List<int>> _readFile(String? path) {
    if (path == null) {
      throw StateError('Il file selezionato non è accessibile');
    }
    return File(path).readAsBytes();
  }
}
