//
//  ViewModel.swift
//  GitHub Repository Search
//
//  Created by Ryo on 2021/09/29.
//

/// ViewModelのベース
public protocol ViewModel : AnyObject {

    /// Viewへの入力
    associatedtype ViewInput
    /// Viewへの出力
    associatedtype ViewOutput

    /// Viewへの出力を取得する
    /// - Parameter input: Viewへの入力
    /// - Returns: Viewへの出力
    func transform(_ input: ViewInput) -> ViewOutput
}
