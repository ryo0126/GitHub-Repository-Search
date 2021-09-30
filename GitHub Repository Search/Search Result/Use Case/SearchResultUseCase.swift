//
//  SearchResultUseCase.swift
//  GitHub Repository Search
//
//  Created by Ryo on 2021/09/30.
//

import RxSwift

public protocol SearchResultUseCaseProtocol {

    /// GitHubレポジトリを検索する
    /// - Parameters:
    ///   - query: 検索文字列
    ///   - countPerPage: 一ページあたりの表示レポジトリ数
    ///   - page: 表示するページ番号
    /// - Returns: 検索結果の`Observable`
    func searchRepositories(for query: String, countPerPage: Int, in page: Int) -> Observable<[Repository]>
}

public class SearchResultUseCase<R : GitHubRepository> : SearchResultUseCaseProtocol {

    private let repository: R

    public init(repository: R) {
        self.repository = repository
    }

    public func searchRepositories(for query: String, countPerPage: Int, in page: Int) -> Observable<[Repository]> {
        return repository.searchRepositories(for: query, countPerPage: countPerPage, in: page)
    }
}
