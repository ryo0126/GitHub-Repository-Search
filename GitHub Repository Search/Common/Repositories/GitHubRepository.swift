//
//  GitHubRepository.swift
//  GitHub Repository Search
//
//  Created by Ryo on 2021/09/29.
//

import Foundation
import RxSwift

// MARK: - Protocol
public protocol GitHubRepository {

    /// GitHubレポジトリを検索する
    /// - Parameter query: 検索文字列
    /// - Returns: 検索結果の`Observable`
    func searchRepositories(for query: String) -> Observable<[Repository]>
}

public enum GitHubRepositoryError : Error {

    case errorStatusCode(statusCode: Int)
    case decodingBodyFailed
}

// MARK: - Implementation
/// GitHub Search APIのレスポンスボディ
private struct SearchRepositoriesResponse : Codable {

    var total_count: Int
    var incomplete_results: Bool
    var items: [Repository]
}

public class RestGitHubRepository : GitHubRepository {

    public func searchRepositories(for query: String) -> Observable<[Repository]> {
        guard let url = URL(string: SearchRepositories.shared.url) else { fatalError("Failed to instantiate URL with \(SearchRepositories.shared)") }
        let queryAdded = url.withQuery(name: SearchRepositories.Query.query.rawValue, value: query)

        return ObservableRequest.create(requestOf: queryAdded)
            .flatMapLatest { response -> Observable<[Repository]> in
                switch response {
                case .success(let data):
                    guard let response = try? JSONDecoder().decode(SearchRepositoriesResponse.self, from: data) else {
                        return Observable.error(GitHubRepositoryError.decodingBodyFailed)
                    }

                    return Observable.just(response.items)
                case .error(let statusCode):
                    return Observable.error(GitHubRepositoryError.errorStatusCode(statusCode: statusCode))
                }
            }
    }
}
