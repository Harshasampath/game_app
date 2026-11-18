import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var voyagerTorchDevice: AVCaptureDevice?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "game_app/voyager_torch",
      binaryMessenger: engineBridge.applicationRegistrar.messenger())
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      let arguments = call.arguments as? [String: Any]
      let enabled = arguments?["enabled"] as? Bool ?? false
      switch call.method {
      case "isAvailable":
        result(AVCaptureDevice.default(for: .video)?.hasTorch == true)
      case "setKeepAwake":
        UIApplication.shared.isIdleTimerDisabled = enabled && UIApplication.shared.applicationState == .active
        result(nil)
      case "setTorch":
        if !enabled && self.voyagerTorchDevice == nil {
          result(nil)
          return
        }
        if enabled && UIApplication.shared.applicationState != .active {
          result(FlutterError(code: "INACTIVE", message: "Return to the app to send a signal.", details: nil))
          return
        }
        guard let device = self.voyagerTorchDevice ?? AVCaptureDevice.default(for: .video), device.hasTorch else {
          result(FlutterError(code: "NO_TORCH", message: "This device has no flashlight.", details: nil))
          return
        }
        do {
          try device.lockForConfiguration()
          defer { device.unlockForConfiguration() }
          if enabled {
            try device.setTorchModeOn(level: 1.0)
            self.voyagerTorchDevice = device
          } else {
            device.torchMode = .off
            self.voyagerTorchDevice = nil
          }
          result(nil)
        } catch {
          result(FlutterError(code: "TORCH_UNAVAILABLE", message: "Flashlight unavailable. Close other camera apps and try again.", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    NotificationCenter.default.addObserver(
      self, selector: #selector(stopVoyagerSignal),
      name: UIApplication.willResignActiveNotification, object: nil)
  }

  @objc private func stopVoyagerSignal() {
    UIApplication.shared.isIdleTimerDisabled = false
    guard let device = voyagerTorchDevice else { return }
    do {
      try device.lockForConfiguration()
      defer { device.unlockForConfiguration() }
      device.torchMode = .off
      voyagerTorchDevice = nil
    } catch {
      // The system may already have reclaimed the camera.
    }
  }
}
