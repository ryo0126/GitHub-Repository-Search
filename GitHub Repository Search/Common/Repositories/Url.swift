//
//  Url.swift
//  GitHub Repository Search
//
//  Created by Ryo on 2021/09/29.
//

// MARK: - Base URL
/// ベースURL
public let baseUrl = "https://api.github.com"

/// GitHub APIのURL
public protocol GitHubUrl {

    associatedtype AssociatedQuery

    var endPoint: String { get }

    /// フルURL(ベースURL+エンドポイント)
    var url: String { get }
}

extension GitHubUrl {

    public var url: String {
        return "\(baseUrl)\(endPoint)"
    }
}

// MARK: - APIs
public final class SearchRepositories : GitHubUrl {

    public enum Query : String {
        case query = "q"
    }

    public typealias AssociatedQuery = Query

    public static let shared = SearchRepositories()
    public let endPoint: String = "/search/repositories"

    private init() {}
}
