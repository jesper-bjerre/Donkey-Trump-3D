import Foundation
import Security

protocol InstallationCredentialProviding: Sendable {
    func authorization() async throws -> String
}

actor InstallationCredentialStore: InstallationCredentialProviding {
    static let shared = InstallationCredentialStore()
    private let file: URL
    init(file: URL? = nil) {
        self.file = file ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Moderation/installation-secret")
    }
    func authorization() throws -> String {
        do { return try readOrCreate() }
        catch { throw HighscoreServiceError.credentialUnavailable }
    }
    private func readOrCreate() throws -> String {
        let manager = FileManager.default
        let bytes: Data
        if manager.fileExists(atPath: file.path) {
            bytes = try Data(contentsOf: file)
            guard bytes.count == 32 else { throw HighscoreServiceError.credentialUnavailable }
        } else {
            try manager.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            var random = [UInt8](repeating: 0, count: 32)
            guard SecRandomCopyBytes(kSecRandomDefault, random.count, &random) == errSecSuccess else { throw HighscoreServiceError.credentialUnavailable }
            bytes = Data(random)
            try bytes.write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        }
        // A failure here also fails online writes; never rotate an existing secret.
        var url = file
        var values = URLResourceValues(); values.isExcludedFromBackup = true
        try url.setResourceValues(values)
        return "Bearer " + bytes.base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
}
