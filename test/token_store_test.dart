import 'package:bacheca_app/core/token_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores and clears an in-memory token', () async {
    // AC-NF-07
    final store = InMemoryTokenStore('initial');
    expect(await store.read(), 'initial');

    await store.write('updated');
    expect(await store.read(), 'updated');

    await store.clear();
    expect(await store.read(), isNull);
  });
}
