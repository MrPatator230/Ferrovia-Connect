import Foundation

enum TrafficInfoError: Error, LocalizedError {
    case invalidURL
    case badResponse(statusCode: Int, body: String?)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL invalide"
        case .badResponse(let code, let body):
            if let b = body, !b.isEmpty { return "Mauvaise réponse du serveur (\(code)): \(b)" }
            return "Mauvaise réponse du serveur (\(code))"
        case .serverError(let msg): return msg
        }
    }
}

struct TrafficInfoService {
    // Base URL configurable via Info.plist key `TrafficInfoAPIBaseURL`.
    // If you deploy `api_infotrafic.php` to your domain, set that full URL in Info.plist
    // e.g. https://api.yourdomain.tld/api_infotrafic.php
    static var baseURLString: String {
        if let configured = Bundle.main.object(forInfoDictionaryKey: "TrafficInfoAPIBaseURL") as? String,
           !configured.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return configured
        }
        // Default placeholder - change before release to your real domain endpoint
        return "https://mr-patator.fr/api_infotrafic.php"
    }

    private struct ApiWrapper: Codable {
        let success: Bool
        let data: [TrafficInfoItem]?
        let error: String?
    }

    static func fetch(region: String) async throws -> [TrafficInfoItem] {
        // Try primary URL, if fails try http fallback (helps debug TLS or redirect issues)
        let urlsToTry: [URL]
        if let primary = URL(string: baseURLString) {
            if baseURLString.lowercased().hasPrefix("https://") {
                var httpFallback = baseURLString
                if httpFallback.lowercased().hasPrefix("https://") {
                    httpFallback = "http://" + httpFallback.dropFirst("https://".count)
                }
                urlsToTry = [primary, URL(string: httpFallback)!]
            } else {
                urlsToTry = [primary]
            }
        } else {
            throw TrafficInfoError.invalidURL
        }

        var lastError: Error? = nil
        for url in urlsToTry {
            do {
                var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
                comps?.queryItems = [URLQueryItem(name: "action", value: "getByRegion"), URLQueryItem(name: "region", value: region)]
                guard let finalURL = comps?.url else { throw TrafficInfoError.invalidURL }

                var request = URLRequest(url: finalURL)
                request.httpMethod = "GET"
                request.timeoutInterval = 20

                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse else { throw TrafficInfoError.badResponse(statusCode: -1, body: nil) }

                let bodyString = String(data: data, encoding: .utf8)

                if http.statusCode != 200 {
                    // Try to parse error message from body
                    if let parsed = try? JSONDecoder().decode(ApiWrapper.self, from: data), let err = parsed.error {
                        throw TrafficInfoError.badResponse(statusCode: http.statusCode, body: err)
                    }
                    throw TrafficInfoError.badResponse(statusCode: http.statusCode, body: bodyString)
                }

                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let wrapper = try decoder.decode(ApiWrapper.self, from: data)
                if !wrapper.success { throw TrafficInfoError.serverError(wrapper.error ?? "Server returned success = false") }
                return wrapper.data ?? []
            } catch {
                lastError = error
                // try next URL
            }
        }
        throw lastError ?? TrafficInfoError.serverError("Unknown error")
    }

    // Debug helper: fetch raw response body as String (useful while debugging server-side issues).
    static func fetchRaw(region: String) async throws -> String {
        guard let primary = URL(string: baseURLString) else { throw TrafficInfoError.invalidURL }
        var candidates: [URL] = [primary]
        if baseURLString.lowercased().hasPrefix("https://") {
            if let httpFallback = URL(string: "http://" + baseURLString.dropFirst("https://".count)) {
                candidates.append(httpFallback)
            }
        }

        var lastErr: Error? = nil
        for base in candidates {
            var comps = URLComponents(url: base, resolvingAgainstBaseURL: false)
            comps?.queryItems = [URLQueryItem(name: "action", value: "getByRegion"), URLQueryItem(name: "region", value: region)]
            guard let finalURL = comps?.url else { continue }

            do {
                let (data, response) = try await URLSession.shared.data(from: finalURL)
                guard let http = response as? HTTPURLResponse else { throw TrafficInfoError.badResponse(statusCode: -1, body: nil) }
                let bodyString = String(data: data, encoding: .utf8) ?? "(non-UTF8)"
                if http.statusCode != 200 {
                    throw TrafficInfoError.badResponse(statusCode: http.statusCode, body: bodyString)
                }
                return bodyString
            } catch {
                lastErr = error
            }
        }
        throw lastErr ?? TrafficInfoError.serverError("Unknown error")
    }
}
