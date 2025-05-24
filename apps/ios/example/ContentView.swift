import PdSdk
import SwiftUI

struct ContentView: View {
    let sdkVersion = PdSdk.version()
    @State private var world: World?
    @State private var helloResult: String?
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Text("Using SDK \(sdkVersion)")
            
            if let result = helloResult {
                Text(result)
                    .foregroundColor(.green)
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            
            Button("Call Hello") {
                Task {
                    await callHello()
                }
            }
            .padding()
        }
        .padding()
        .onAppear {
            // Initialize World instance when view appears
            world = World(attribute: "SwiftUI")
        }
    }
    
    private func callHello() async {
        guard let world = world else { return }
        
        do {
            let result = try await world.hello()
            helloResult = result
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            helloResult = nil
        }
    }
}

#Preview {
    ContentView()
}
