String? validateCompanyName(String? value) {
  final name = value?.trim() ?? '';
  return name.length >= 2 && name.length <= 100
      ? null
      : 'Inserisci una ragione sociale valida';
}

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(email)
      ? null
      : 'Email non valida';
}

String? validateApplicantName(String? value, String fieldLabel) {
  final name = value?.trim() ?? '';
  return name.isNotEmpty && name.length <= 60
      ? null
      : 'Il $fieldLabel deve contenere da 1 a 60 caratteri';
}

String? validatePassword(String? value) {
  final password = value ?? '';
  return password.length >= 8 && password.length <= 128
      ? null
      : 'La password deve contenere da 8 a 128 caratteri';
}

String? validateJobTitle(String? value) {
  final title = value?.trim() ?? '';
  return title.length >= 3 && title.length <= 120
      ? null
      : 'Il titolo deve contenere da 3 a 120 caratteri';
}

String? validateJobDescription(String? value) {
  final description = value?.trim() ?? '';
  return description.length >= 10 && description.length <= 5000
      ? null
      : 'La descrizione deve contenere da 10 a 5000 caratteri';
}

String? validateJobLocation(String? value) {
  final location = value?.trim() ?? '';
  return location.length <= 100
      ? null
      : 'La località non può superare 100 caratteri';
}
