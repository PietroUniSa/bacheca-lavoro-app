class PickedCv {
  const PickedCv({required this.name, required this.bytes});

  final String name;
  final List<int> bytes;
}

abstract class CvPicker {
  Future<PickedCv?> pick();
}
