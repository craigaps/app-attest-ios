import Foundation
import DeviceCheck
/// A model that represents a stored attestation key and its associated usage count.
///
/// This struct conforms to `Codable`, allowing it to be easily saved to and
/// loaded from persistent storage such as `UserDefaults`.
struct KeyInfo: Codable {
    /// A unique string identifier for the attested key.
    var id: String
    
    /// The number of times the key has been asserted or used.
    var count: Int
}

/// Manages the storage and retrieval of attestation-related data using UserDefaults.
/// Uses the modern `@Observable` macro for SwiftUI reactivity.
@Observable
class Storage {
    let appId = "{TEAM_ID}.com.ibm.verify.example.appattest"
    
    private let defaults = UserDefaults.standard
    private let service = AttestationService(baseURL: URL(string: "https://localhost:3000")!)
    private let urlSession = URLSession(configuration: .default, delegate: CertificateSessionDelegate(), delegateQueue: nil)
    
    /// The currently stored App Attest key ID and assertion count.
    var keyInfo: KeyInfo? {
        didSet {
            saveKeyId(keyInfo)
        }
    }
    
    
    init() {
       self.keyInfo = getKeyId()
    }
    
    // MARK: - Storage
    
    /// Saves a value to UserDefaults for the specified data type.
    private func saveKeyId(_ value: Codable) {
        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(value)
            defaults.set(encoded, forKey: "keyID")
        }
        catch {
            print("Failed to encode keyID:", error)
        }
    }
    
    /// Retrieves a stored value from UserDefaults for the specified data type.
    private func getKeyId<T: Codable>() -> T? {
        guard let data = UserDefaults.standard.data(forKey: "keyID") else {
            print("No data found for keyID")
            return nil
        }
        
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(T.self, from: data)
        }
        catch {
            print("Failed to decode keyID:", error)
        }
        return nil
    }
    
    /// Clears the stored value for the specified data type.
    func clearKeyId() {
        keyInfo = nil
    }
    
    // MARK: - Device Check
    
    /// Generates a new App Attest key asynchronously using Apple's `DCAppAttestService`.
    ///
    /// This function checks if the device supports App Attest, then attempts to create a new attestation key.
    /// If successful, it returns the generated `keyId`. If the service isn't supported or the key fails to generate,
    /// an error is thrown.
    ///
    /// > Note: Requires iOS 14.0+ and an Apple App Attest entitlement configured.
    ///
    /// - Returns: A `String` representing the generated App Attest key identifier.
    /// - Throws: An error if App Attest is unsupported or key generation fails.
    func createAttestation() async throws {
        guard DCAppAttestService.shared.isSupported else {
            throw DeviceCheckError.unsupportedDevice
        }
        
        // Step 1: Request challenge from server
        let challengeResult = try await service.requestChallenge()
        print("Challenge: \(challengeResult.value)")
        
        // Step 2: Generate App Attest key
        let keyId = try await DCAppAttestService.shared.generateKey()
        print("KeyID: \(keyId)")
        
        // Step 3: Hash the challenge
        guard let challengeData = challengeResult.clientDataHash else {
            throw DeviceCheckError.invalidChallenge
        }
        
        // Step 4: Generate attestation object
        let attestationObject = try await DCAppAttestService.shared.attestKey(keyId, clientDataHash: challengeData)
        
        // Step 5: Send attestation to server for validation
        let attestationResult = try await service.validateAttestation(
            attestation: attestationObject.base64EncodedString(),
            keyId: keyId,
            clientDataHash: challengeData.base64EncodedString(),
            appId: appId,
            userId: "foo"
        )
        
        print("Attestation result: \(attestationResult)")
        
        // Step 6: Save key ID if validation succeeded
        if attestationResult.result == keyId {
            self.keyInfo = KeyInfo(id: keyId, count: 0)
        }
        else {
            throw DeviceCheckError.serverError("Attestation failed: server returned unexpected key ID.")
        }
    }
    
    /// Performs an App Attest assertion flow:
    /// 1. Verifies device support for App Attest
    /// 2. Requests a challenge from the attestation server
    /// 3. Retrieves the previously generated App Attest key ID
    /// 4. Generates an assertion using the key and challenge
    /// 5. Sends the assertion to the server for validation
    ///
    /// - Throws: An `AppAttestError` if any step fails, including unsupported devices,
    ///           missing challenge data, missing key ID, or server-side validation errors.
    func createAssertion() async throws {
        // Step 1: Check device support
        guard DCAppAttestService.shared.isSupported else {
            throw DeviceCheckError.unsupportedDevice
        }
        
        // Step 2: Request challenge from server
        let challengeResult = try await service.requestChallenge()
        print("Challenge: \(challengeResult.value)")
        
        // Step 3: Hash the challenge
        guard let challengeData = challengeResult.clientDataHash else {
            throw DeviceCheckError.invalidChallenge
        }
        
        // Step 4: Retrieve key ID from storage
        guard let keyInfo = self.keyInfo else {
            throw DeviceCheckError.missingKeyId
        }
        
        // Step 5: Generate assertion using App Attest
        let assertionObject = try await DCAppAttestService.shared.generateAssertion(keyInfo.id, clientDataHash: challengeData)
        
        // Step 6: Send assertion to server for verification
        let assertionResult = try await service.verifyAssertion(
            assertion: assertionObject.base64EncodedString(),
            keyId: keyInfo.id,
            clientDataHash: challengeData.base64EncodedString(),
            appId: appId,
            challenge: challengeResult.value
        )
        
        print("Assertion result: \(assertionResult)")
        
        // Step 7: Handle server-side error
        if let error = assertionResult.error {
            throw DeviceCheckError.serverError(error)
        }
        
        if let value = assertionResult.result, let count = Int(value) {
            self.keyInfo?.count = count
        }
        else {
            throw DeviceCheckError.serverError("Assertion verification failed: server returned unexpected error.")
        }
    }
}

extension Storage {
    static func formatDate(from input: String) -> String? {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        inputFormatter.locale = Locale(identifier: "en_AU")

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd MMMM yyyy"
        outputFormatter.locale = Locale(identifier: "en_AU")

        if let date = inputFormatter.date(from: input) {
            return outputFormatter.string(from: date)
        }
        else {
            return nil // Invalid input format
        }
    }
}

// MARK: Errors

public enum DeviceCheckError: LocalizedError {
    case unsupportedDevice
    case invalidChallenge
    case missingKeyId
    case serverError(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedDevice:
            return "This device does not support App Attest."
        case .invalidChallenge:
            return "Challenge data could not be hashed."
        case .missingKeyId:
            return "The key identifier could not be retrieved."
        case .serverError(let message):
            return message
        }
    }
}
