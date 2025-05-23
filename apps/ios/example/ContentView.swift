import PdSdk
import SwiftUI

struct ContentView: View {

    let sdkVersion = PdSdk.version()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Text("Using SDK \(sdkVersion)")

        }
        .padding()
    }
}

#Preview {
    ContentView()
}
