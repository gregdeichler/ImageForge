import SwiftUI

@main
struct ImageForgeApp: App {
    @State private var queue = BatchQueueModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(queue)
                .frame(minWidth: 760, minHeight: 520)
        }
        .defaultSize(width: 1080, height: 700)
        .windowResizability(.contentMinSize)
    }
}
