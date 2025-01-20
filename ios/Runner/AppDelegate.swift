import Flutter
import UIKit
import GoogleMaps
import FirebaseCore
import FirebaseFirestore

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Inicializar Google Maps
    GMSServices.provideAPIKey("AIzaSyCSp5RbLBZKMLHT0RJH3Zk5JRXZ4LOrQYc")
    
    // Inicializar Firebase
    FirebaseApp.configure()
    
    // Acceder a Firestore
    do {
      let firestore = Firestore.firestore()
      print("Firestore inicializado: \(firestore)")
    } catch let error {
      print("Error al inicializar Firestore: \(error.localizedDescription)")
    }
    
    // Registrar los plugins generados
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
