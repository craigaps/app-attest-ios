import SwiftUI

/// A SwiftUI view that displays a stored key identifier and its associated count
/// in a styled `GroupBox`. Includes a delete button with a disabled state.
///
/// This component is useful for presenting key information with minimal layout,
/// and lets the user trigger deletion via a trash icon.
///
/// - Parameters:
///   - keyID: A unique identifier string representing the stored key.
///   - count: An integer representing the number of keys (or an associated value).
///   - isProcessing: A Boolean flag that disables the trash icon while processing.
///   - onDelete: A closure executed when the user taps the trash icon.
struct KeyIdentifierGroup: View {
    let keyID: String
    let count: Int
    let isProcessing: Bool
    let onDelete: () -> Void

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                /// Section label describing the content
                Text("Stored Key Identifier")
                    .font(.caption)
                    .foregroundColor(.secondary)

                /// Actual key value displayed in monospaced font for readability
                Text(keyID)
                    .font(.monospaced(.body)())
                    .minimumScaleFactor(0.7)
                    .cornerRadius(8)
                
                /// Descriptive header text above the key info
                Text("Assertion Count")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 12)
                
                /// Display the count using a monospaced body font for visual clarity
                Text("\(count)")
                    .font(.monospaced(.body)())
                    .minimumScaleFactor(0.7)
                    .cornerRadius(8)
                

                /// Trash icon aligned to the trailing edge, disabled if `isProcessing` is true
                HStack {
                    Spacer()
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                        .disabled(isProcessing)
                        .onTapGesture {
                            onDelete()
                        }
                }
            }
        }
    }
}



#Preview {
    KeyIdentifierGroup(keyID: UUID().uuidString, count: 2, isProcessing: false, onDelete: {})
}
