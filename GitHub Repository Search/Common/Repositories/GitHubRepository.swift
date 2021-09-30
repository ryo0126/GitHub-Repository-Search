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
    /// - Parameters:
    ///   - query: 検索文字列
    ///   - countPerPage: 一ページあたりの表示レポジトリ数
    ///   - page: 表示するページ番号
    /// - Returns: 検索結果の`Observable`
    func searchRepositories(for query: String, countPerPage: Int, in page: Int) -> Observable<[Repository]>
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

    public func searchRepositories(for query: String, countPerPage: Int, in page: Int) -> Observable<[Repository]> {
        guard let url = URL(string: SearchRepositories.shared.url) else { fatalError("Failed to instantiate URL with \(SearchRepositories.shared)") }
        let queryAdded = url.withQueries([
            URLQueryItem(name: SearchRepositories.Query.query.rawValue, value: query),
            URLQueryItem(name: SearchRepositories.Query.countPerPage.rawValue, value: String(countPerPage)),
            URLQueryItem(name: SearchRepositories.Query.inPage.rawValue, value: String(page)),
        ])

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
