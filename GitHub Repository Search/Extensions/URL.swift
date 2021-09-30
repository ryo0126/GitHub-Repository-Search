//
//  URL.swift
//  GitHub Repository Search
//
//  Created by Ryo on 2021/09/29.
//

import Foundation

extension URL {

    /// クエリを追加したインスタンスを返す
    /// - Parameters:
    ///   - name: クエリ名
    ///   - value: 値
    /// - Returns: クエリを追加したインスタンス
    public func withQuery(name: String, value: String) -> URL {
        return withQueries([URLQueryItem(name: name, value: value)])
    }

    /// 複数のクエリを追加したインスタンスを返す
    /// - Parameter queries: 追加するクエリ
    /// - Returns: `queries`を追加したインスタンス
    public func withQueries(_ queries: [URLQueryItem]) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: self.baseURL != nil) else {
            fatalError("Failed to instantiate URLComponents with \(self).")
        }
        components.queryItems = queries + (components.queryItems ?? [])
        return components.url!
    }
}
