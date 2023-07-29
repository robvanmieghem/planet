import 'package:test/test.dart';
import 'package:planet/appmodel.dart';

void main() {
  group('Application State', () {
    test('set network', () {
      final model = AppState();
      var listenerCalled = false;
      model.addListener(() {
        expect(model.testnet, true);
        listenerCalled = true;
      });
      model.setNetwork(true);
      expect(listenerCalled, true);
    });
  });
}
