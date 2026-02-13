import SwiftUI

@main
struct JarvisApp: App {
    @StateObject private var viewModel = ChatViewModel(gatewayClient: GatewayClient())

    var body: some Scene {
        WindowGroup {
            ChatView(viewModel: viewModel)
        }
    }
}
