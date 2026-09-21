import SwiftUI

@main
struct LingerApp: App {
    var body: some Scene {
        WindowGroup {
            FireSensorView(viewModel: FireSensorViewModel())
        }
    }
}
