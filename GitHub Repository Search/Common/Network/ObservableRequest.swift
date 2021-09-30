//
//  ObservableRequest.swift
//  GitHub Repository Search
//
//  Created by Ryo on 2021/09/29.
//

import Foundation
import RxSwift

/// レスポンス
public enum Response {
    case success(responseData: Data)
    case error(statusCode: Int)
}

/// ObservableなURLリクエストを発行する
public class ObservableRequest {

    /// GETリクエストを発行する
    /// - Parameter url: 宛先
    /// - Returns: レスポンスのObservable
    public static func create(requestOf url: URL) -> Observable<Response> {
        return Observable.create { observer in
            let urlRequest = URLRequest(url: url)
            let session = URLSession(configuration: .ephemeral)
            // 通信タスク
            let task = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
                // エラーがあったらエラーを流して終了
                if let error = error {
                    observer.onError(error)
                    observer.onCompleted()
                    return
                }
                // レスポンス取得
                guard let response = response as? HTTPURLResponse else { fatalError("Failed to cast response as HTTPURLResponse.") }

                // STATUS OKのときのみデータを流す
                if response.statusCode == 200 {
                    guard let data = data else { fatalError("Failed to get data.") }
                    observer.onNext(.success(responseData: data))
                } else {
                    observer.onNext(.error(statusCode: response.statusCode))
                }
                observer.onCompleted()
            })
            // 通信を開始
            task.resume()
            return Disposables.create {
                // 購読解除されたらタスクキャンセルする
                task.cancel()
            }
        }
    }
}
