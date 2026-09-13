import Foundation
import AuthenticationServices
import CryptoKit

/// Manages OAuth 2.0 PKCE authentication flow for Google Drive using ASWebAuthenticationSession
public final class GoogleDriveAuthManager: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    public static let shared = GoogleDriveAuthManager()
    
    @Published public var isAuthenticated: Bool = false
    @Published public var userEmail: String?
    
    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiry: Date?
    private var currentAuthSession: ASWebAuthenticationSession?
    
    private let tokenStorageKey = "com.sonance.google_drive_tokens"
    
    private override init() {
        super.init()
        loadStoredTokens()
    }
    
    // MARK: - ASWebAuthenticationPresentationContextProviding
    
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return ASPresentationAnchor()
        }
        return window
    }
    
    // MARK: - OAuth 2.0 PKCE Flow
    
    public func signIn() async throws {
        // Generate PKCE Code Verifier & Challenge
        let codeVerifier = generateRandomString(length: 64)
        guard let codeChallenge = generateCodeChallenge(from: codeVerifier) else {
            throw NSError(domain: "SonanceAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate PKCE challenge"])
        }
        
        var components = URLComponents(string: AppConstants.GoogleDrive.authEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: AppConstants.GoogleDrive.clientId),
            URLQueryItem(name: "redirect_uri", value: AppConstants.GoogleDrive.redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: AppConstants.GoogleDrive.scopes.joined(separator: " ")),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "prompt", value: "consent"),
            URLQueryItem(name: "access_type", value: "offline")
        ]
        
        guard let authURL = components.url else {
            throw NSError(domain: "SonanceAuth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid Auth URL"])
        }
        
        let callbackScheme = "sonance"
        
        let authCode: String = try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callbackURL = callbackURL,
                      let urlComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                      let code = urlComponents.queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: NSError(domain: "SonanceAuth", code: -3, userInfo: [NSLocalizedDescriptionKey: "No code received"]))
                    return
                }
                continuation.resume(returning: code)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.currentAuthSession = session
            session.start()
        }
        
        // Exchange Code for Access Token
        try await exchangeCodeForTokens(code: authCode, codeVerifier: codeVerifier)
    }
    
    private func exchangeCodeForTokens(code: String, codeVerifier: String) async throws {
        var request = URLRequest(url: URL(string: AppConstants.GoogleDrive.tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParams = [
            "client_id": AppConstants.GoogleDrive.clientId,
            "code": code,
            "code_verifier": codeVerifier,
            "grant_type": "authorization_code",
            "redirect_uri": AppConstants.GoogleDrive.redirectUri
        ]
        
        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown token error"
            throw NSError(domain: "SonanceAuth", code: -4, userInfo: [NSLocalizedDescriptionKey: errorText])
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let access = json["access_token"] as? String {
            self.accessToken = access
            self.refreshToken = json["refresh_token"] as? String ?? self.refreshToken
            let expiresIn = json["expires_in"] as? TimeInterval ?? 3600
            self.tokenExpiry = Date().addingTimeInterval(expiresIn)
            
            saveTokensToDisk()
            await MainActor.run {
                self.isAuthenticated = true
            }
        }
    }
    
    /// Retrieves a valid access token, refreshing automatically if expired
    public func getValidAccessToken() async throws -> String {
        if let token = accessToken, let expiry = tokenExpiry, expiry > Date().addingTimeInterval(60) {
            return token
        }
        
        guard let refreshToken = refreshToken else {
            throw NSError(domain: "SonanceAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication required"])
        }
        
        // Refresh token
        var request = URLRequest(url: URL(string: AppConstants.GoogleDrive.tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParams = [
            "client_id": AppConstants.GoogleDrive.clientId,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]
        
        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let newAccess = json["access_token"] as? String {
            self.accessToken = newAccess
            let expiresIn = json["expires_in"] as? TimeInterval ?? 3600
            self.tokenExpiry = Date().addingTimeInterval(expiresIn)
            saveTokensToDisk()
            return newAccess
        }
        
        throw NSError(domain: "SonanceAuth", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to refresh token"])
    }
    
    public func signOut() {
        self.accessToken = nil
        self.refreshToken = nil
        self.tokenExpiry = nil
        UserDefaults.standard.removeObject(forKey: tokenStorageKey)
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.userEmail = nil
        }
    }
    
    // MARK: - Token Storage
    
    private func saveTokensToDisk() {
        var dict: [String: Any] = [:]
        if let access = accessToken { dict["access"] = access }
        if let refresh = refreshToken { dict["refresh"] = refresh }
        if let expiry = tokenExpiry { dict["expiry"] = expiry.timeIntervalSince1970 }
        UserDefaults.standard.set(dict, forKey: tokenStorageKey)
    }
    
    private func loadStoredTokens() {
        guard let dict = UserDefaults.standard.dictionary(forKey: tokenStorageKey) else { return }
        self.accessToken = dict["access"] as? String
        self.refreshToken = dict["refresh"] as? String
        if let expiryTime = dict["expiry"] as? TimeInterval {
            self.tokenExpiry = Date(timeIntervalSince1970: expiryTime)
        }
        self.isAuthenticated = (accessToken != nil || refreshToken != nil)
    }
    
    // MARK: - Crypto Helpers
    
    private func generateRandomString(length: Int) -> String {
        var buffer = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &buffer)
        return Data(buffer).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    private func generateCodeChallenge(from verifier: String) -> String? {
        guard let data = verifier.data(using: .utf8) else { return nil }
        let hashed = SHA256.hash(data: data)
        return Data(hashed).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
}
