import Foundation
import CryptoKit

/// A client for interacting with the attestation web service.
public struct AttestationService {
    /// The base URL of the attestation server (e.g., "https://localhost").
    public let baseURL: URL
    private let session: URLSession

    public init(baseURL: URL) {
        self.baseURL = baseURL
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        
        self.session = URLSession(configuration: config, delegate: CertificateSessionDelegate(), delegateQueue: nil)
    }

    /// Represents a challenge response from the server.
    public struct ChallengeResponse: Decodable {
        public let value: String
        
        private enum CodingKeys: String, CodingKey {
            case value = "challenge"
        }
    }

    /// Represents a generic server response.
    public struct ServerResponse: Decodable {
        public let error: String?
        public let result: String?
    }

    // MARK: - Endpoints

    /// Requests a new attestation challenge from the server.
    /// - Returns: ChallengeResponse containing the challenge and its ID.
    public func requestChallenge() async throws -> ChallengeResponse {
        let url = baseURL.appendingPathComponent("/attest/challenge")
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(ChallengeResponse.self, from: data)
    }

    /// Validates an attestation with the server.
    /// - Parameters:
    ///   - attestation: The attestation object/data (Base64 or JSON).
    ///   - keyId: The key identifier.
    ///   - challengeId: The challenge ID received from `requestChallenge`.
    ///   - appId: The 10-digit team identifier and app bundle identifier. For example `A1B2C3D4E5.com.example.app`
    ///   - userId: The user performing the attestation.
    /// - Returns: ServerResponse indicating success or error.
    public func validateAttestation(attestation: String, keyId: String, clientDataHash: String, appId: String, userId: String) async throws -> ServerResponse {
        let url = baseURL.appendingPathComponent("/attest/validate")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "attestation": attestation,
            "keyId": keyId,
            "clientDataHash": clientDataHash,
            "appId": appId,
            "userId": userId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(ServerResponse.self, from: data)
    }

    /// Verifies an assertion with the server.
    /// - Parameters:
    ///   - assertion: The assertion object/data (Base64 or JSON).
    ///   - keyId: The key identifier.
    ///   - clientDataHash: The hash of the client data.
    ///   - appId: The 10-digit team identifier and app bundle identifier. For example `A1B2C3D4E5.com.example.app`
    ///   - challenge: The challenge response from the server.
    /// - Returns: ServerResponse indicating success or error.
    public func verifyAssertion(assertion: String, keyId: String, clientDataHash: String, appId: String, challenge: String) async throws -> ServerResponse {
        let url = baseURL.appendingPathComponent("/attest/verify")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "assertion": assertion,
            "keyId": keyId,
            "clientDataHash": clientDataHash,
            "appId": appId,
            "challenge": challenge
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(ServerResponse.self, from: data)
    }
}

public extension AttestationService.ChallengeResponse {
    var clientDataHash: Data? {
        get {
            // 1. Convert the challenge string to Data
            guard let challengeData = value.data(using: .utf8) else {
                return nil
            }
            
            // 2. Hash the data using SHA256
            let hash = SHA256.hash(data: challengeData)
            
            // 3. Return the hash as Data
            return Data(hash)
        }
    }
}
