import SwiftUI
import FirebaseCore

@main
struct KelimeMayinlariApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            StartView()
           
        }
        
    }
    
}
