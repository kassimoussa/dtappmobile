import 'dart:async';

import 'package:dtservices/utils/release_logging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ce que `debugPrint` écrit pendant [body], capté au niveau de `print`.
Future<List<String>> _printed(FutureOr<void> Function() body) async {
  final lines = <String>[];
  await runZoned(
    () async => body(),
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => lines.add(line),
    ),
  );
  return lines;
}

void main() {
  final original = debugPrint;
  tearDown(() => debugPrint = original);

  test('contrôle : sans silence, debugPrint écrit dans le journal', () async {
    final lines = await _printed(() => debugPrint('jeton-secret'));

    expect(lines, contains('jeton-secret'));
  });

  test('en release, debugPrint n\'écrit plus rien', () async {
    silenceDebugPrintInRelease(isRelease: true);

    final lines = await _printed(() {
      debugPrint('jeton-secret');
      debugPrint('multi\nligne', wrapWidth: 20);
    });

    expect(lines, isEmpty);
  });

  test('hors release (debug, profile), les journaux restent', () async {
    silenceDebugPrintInRelease(isRelease: false);

    final lines = await _printed(() => debugPrint('visible'));

    expect(lines, contains('visible'));
  });

  test('un test tourne en debug : le réglage par défaut ne coupe rien', () {
    // kReleaseMode est faux ici ; le défaut ne doit donc pas toucher debugPrint.
    expect(kReleaseMode, isFalse);
    silenceDebugPrintInRelease();

    expect(identical(debugPrint, original), isTrue);
  });
}
