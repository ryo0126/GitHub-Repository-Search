//
//  RxSwift.swift
//  GitHub Repository Search
//
//  Created by Ryo on 2021/09/30.
//

import RxSwift

extension Observable {

    /// 空のObservableに変換する
    public func mapToVoid() -> Observable<Void> {
        return map { _ in () }
    }
}
