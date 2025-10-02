//
//  Ar3D_ARG_Network.swift
//  AR3D_ARG
//
//  Created by Arthur Woodlee on 2/10/2025.
//
import SwiftUI

enum NetworkError: Error {
    case invalidURL
    case downloadFailed(String)
    case noData
    case invalidJSON
    case duplicateName(String)
    case parsingFailed(String)
    case notImplemented(String)

    var message: String {
        switch self {
        case .invalidURL:
            return "Invalid URL format."
        case .downloadFailed(let msg):
            return "Download error: \(msg)"
        case .noData:
            return "No data received."
        case .invalidJSON:
            return "File is not valid or missing required fields."
        case .duplicateName(let name):
            return "Dataset \"\(name)\" already exists."
        case .parsingFailed(let msg):
            return "Failed to parse JSON: \(msg)"
        case .notImplemented(let feature):
            return "Feature not implemented: \(feature)"
        }
    }
}

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    private let fileManager = FileManager.default
    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func fetchJSON(from urlString: String, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.downloadFailed(error.localizedDescription)))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.noData))
                }
                return
            }

            DispatchQueue.main.async {
                completion(.success(data))
            }
        }.resume()
    }

    func fetchCSV(from urlString: String, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        completion(.failure(.notImplemented("CSV fetching not yet implemented.")))
    }

    func fetchREST(from urlString: String, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        completion(.failure(.notImplemented("RESTful fetching not yet implemented.")))
    }
}
