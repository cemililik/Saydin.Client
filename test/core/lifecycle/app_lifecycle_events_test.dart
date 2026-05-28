import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/lifecycle/app_lifecycle_events.dart';

void main() {
  group('AppLifecycleEvents', () {
    late AppLifecycleEvents events;

    setUp(() => events = AppLifecycleEvents());
    tearDown(() => events.dispose());

    test('requestReset → resetStream dinleyiciye event yayar', () async {
      final received = <void>[];
      final sub = events.resetStream.listen(received.add);

      events.requestReset();
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      await sub.cancel();
    });

    test('Broadcast: birden fazla dinleyici', () async {
      var aCount = 0;
      var bCount = 0;
      final subA = events.resetStream.listen((_) => aCount++);
      final subB = events.resetStream.listen((_) => bCount++);

      events.requestReset();
      events.requestReset();
      await Future<void>.delayed(Duration.zero);

      expect(aCount, 2);
      expect(bCount, 2);
      await subA.cancel();
      await subB.cancel();
    });

    test('dispose sonrası ekstra event yayını exception fırlatır', () async {
      await events.dispose();
      expect(events.requestReset, throwsStateError);
    });
  });
}
