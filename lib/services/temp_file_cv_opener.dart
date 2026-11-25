import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'cv_opener.dart';

class CvOpenException implements Exception {
  const CvOpenException();
}

class TempFileCvOpener implements CvOpener {
  @override
  Future<void> open(List<int> bytes, String fileName) async {
    final directory = await getTemporaryDirectory();
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final file = File(
      '${directory.path}${Platform.pathSeparator}$safeName',
    );
    await file.writeAsBytes(bytes, flush: true);
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) throw const CvOpenException();
  }
}
