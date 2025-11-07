import Foundation

final class CertificateSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let error = challenge.error {
            print("Cancel authentication challenge. \(error.localizedDescription)")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            print("SSL certificate trust for the challenge protection space was nil.")
            completionHandler(.performDefaultHandling, nil)
            return
        }

       print("Allowing self-signed certificate to be trusted for challenge.")
        
        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }
}
