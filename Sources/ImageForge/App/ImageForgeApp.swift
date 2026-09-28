import SwiftUI

@main
struct ImageForgeApp: App {
    @State private var queue = BatchQueueModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(queue)
                .frame(minWidth: 900, minHeight: 560)
        }
        .windowResizability(.contentMinSize)
    }
}
