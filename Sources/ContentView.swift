import SwiftUI
import TipKit

struct DeviceCheckTip: Tip {
    var title: Text {
        Text("What is Device Check?")
    }

    var message: Text? {
        Text("""
        Device Check is part of Apple’s App Attest service. It helps ensure that server requests come from legitimate instances of your app by using a hardware-backed cryptographic key certified by Apple.
        """)
    }

    var image: Image? {
        Image(systemName: "info.circle")
    }
}

struct ContentView: View {
    @Environment(Storage.self) private var storage
    @State private var showAlert = false
    @State private var errorMessage: String? = nil
    @State private var isProcessing = false
    @State private var assertionSuccess = false
    
    private let tip = DeviceCheckTip()
    
    var body: some View {
        NavigationStack {
            Spacer()
                .popoverTip(tip)
            VStack(alignment: .leading) {
                if let keyInfo = storage.keyInfo {
                    VStack(spacing: 12) {
                        KeyIdentifierGroup(keyID: keyInfo.id,
                                           count: keyInfo.count,
                                           isProcessing: isProcessing,
                                           onDelete: {
                            storage.clearKeyId()
                        })
                        Spacer()
                        
                        // Assertion Success Indicator
                        AnimateImage(
                            isVisible: assertionSuccess,
                            systemImage: "checkmark.circle",
                            imageColor: .green,
                            animationDuration: 0.4,
                            imageSize: 48,
                            text: "Key assertion verified!"
                        )
                        
                        Spacer()
                        
                        Button("Assert Key") {
                            isProcessing = true
                            assertionSuccess = false
                            
                            Task {
                                await handleAssertKey()
                            }
                        }
                        .disabled(isProcessing)
                        .buttonStyle(.fullWidth(tint: Color(.systemBlue)))
                        .alert("Error", isPresented: $showAlert, actions: {
                            Button("OK", role: .cancel) { isProcessing = false }
                        }, message: {
                            if let message = errorMessage {
                                Text(message)
                            }
                        })
                    }
                }
                else {
                    ContentUnavailableView("No Key Found", systemImage: "iphone", description: Text("Get started by attesting your app which will generate the key identifier."))
                    
                    Button("Generate Key") {
                        isProcessing = true
                        
                        Task {
                            await handleGenerateKey()
                        }
                    }
                    .disabled(isProcessing)
                    .buttonStyle(.fullWidth(tint: Color(.systemBlue)))
                    .alert("Error", isPresented: $showAlert, actions: {
                        Button("OK", role: .cancel) { isProcessing = false }
                    }, message: {
                        if let message = errorMessage {
                            Text(message)
                        }
                    })
                }
            }
            .padding()
            .navigationTitle(Text("Device Check"))
        }
    }
    
    func handleGenerateKey() async {
        defer {
            isProcessing = false
        }
        
        do {
            try await storage.createAttestation()
        }
        catch {
            errorMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    func handleAssertKey() async {
        defer {
            isProcessing = false
        }
        
        do {
            try await storage.createAssertion()
            assertionSuccess = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    assertionSuccess = false
                }
            }
        }
        catch {
            errorMessage = error.localizedDescription
            showAlert = true
        }
    }
}

#Preview {
    ContentView()
        .environment(Storage())
}
