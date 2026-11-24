import 'package:flutter/foundation.dart';

/// Rend `debugPrint` muet dans une version release.
///
/// `debugPrint` n'est PAS retiré à la compilation : sans cet appel, chacun de
/// ses appels écrit dans le journal du téléphone (logcat sur Android, console
/// de l'appareil sur iOS), lisible par quiconque branche l'appareil. L'app en
/// compte plusieurs centaines, dont certains affichent des réponses du serveur.
///
/// À appeler une fois, au tout début de `main()`. Les builds debug et profile
/// gardent leurs journaux. [isRelease] n'existe que pour les tests.
///
/// Conséquence : les erreurs du framework (`FlutterError.dumpErrorToConsole`)
/// passent aussi par `debugPrint` et disparaissent des journaux release. Pour
/// suivre les plantages en production, il faut un rapport d'erreurs dédié
/// (Crashlytics ou équivalent), pas le journal du téléphone.
void silenceDebugPrintInRelease({bool isRelease = kReleaseMode}) {
  if (!isRelease) return;
  debugPrint = (String? message, {int? wrapWidth}) {};
}
