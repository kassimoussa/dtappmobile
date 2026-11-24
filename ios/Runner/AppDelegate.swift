import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Couverture posée sur les fenêtres quand l'app passe en arrière-plan.
  private var privacyCovers: [UIView] = []

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps API key (Maps SDK for iOS), restricted by bundle ID in
    // Google Cloud Console.
    GMSServices.provideAPIKey("AIzaSyCz6pyBYPOJSpFGrnZi75t1hFD095w6GdY")
    observePrivacyCover()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // MARK: - Aperçu du sélecteur d'applications

  // iOS prend une capture de l'écran juste après l'entrée en arrière-plan et
  // l'affiche dans le sélecteur d'applications : solde, numéros, reçus. On pose
  // donc une couverture au bleu DT dès `didEnterBackground`, avant la capture.
  // `didEnterBackground` et non `willResignActive` : ce dernier part aussi pour
  // Face ID, le centre de contrôle ou une alerte système, et ferait clignoter
  // l'écran sans raison. Les captures d'écran de l'utilisateur ne sont pas
  // concernées.
  //
  // On passe par les notifications de UIApplication plutôt que par les méthodes
  // du delegate : elles partent aussi avec le cycle de vie par scènes
  // (FlutterSceneDelegate), où les méthodes du delegate ne sont plus appelées.
  private func observePrivacyCover() {
    let center = NotificationCenter.default
    center.addObserver(
      self,
      selector: #selector(showPrivacyCover),
      name: UIApplication.didEnterBackgroundNotification,
      object: nil
    )
    center.addObserver(
      self,
      selector: #selector(hidePrivacyCover),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
  }

  @objc private func showPrivacyCover() {
    guard privacyCovers.isEmpty else { return }
    let dtBlue = UIColor(red: 0.0, green: 36.0 / 255.0, blue: 100.0 / 255.0, alpha: 1.0)

    let windows = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
    for window in windows {
      let cover = UIView(frame: window.bounds)
      cover.backgroundColor = dtBlue
      cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      window.addSubview(cover)
      privacyCovers.append(cover)
    }
  }

  @objc private func hidePrivacyCover() {
    privacyCovers.forEach { $0.removeFromSuperview() }
    privacyCovers.removeAll()
  }
}
