//
//  SearchRepositoryViewModel.swift
//  GitHub Repository Search
//
//  Created by Ryo on 2021/09/29.
//

import RxSwift
import RxCocoa

public class SearchRepositoryViewModel<U : SearchRepositoryUseCaseProtocol> : ViewModel {

    public struct Input {

        /// サーチバーの編集が開始した
        var searchBarDidBeginEditing: Observable<Void>
        /// サーチバーのキャンセルボタンが押された
        var searchBarCancelButtonClicked: Observable<Void>
        /// サーチバーの入力文字列
        var searchBarText: Observable<String>
        /// 検索ボタンが押された
        var searchButtonClicked: Observable<Void>
    }

    public struct Output {

        /// サーチバーのキャンセルボタンを表示する
        var shouldShowSearchBarCancelButton: Driver<Bool>
        /// サーチバーのフォーカスを外す
        var makeSearchBarResignFirstResponder: Driver<Void>
        /// 検索結果を表示する
        var showSearchResultViewController: Driver<String>
    }

    public typealias ViewInput = Input
    public typealias ViewOutput = Output

    private let useCase: U

    public init(useCase: U) {
        self.useCase = useCase
    }

    public func transform(_ input: Input) -> Output {
        // キャンセルボタン表示
        let showSearchBarCancelButton = input.searchBarDidBeginEditing
            .map { true }
        let hideSearchBarCancelButton = input.searchBarCancelButtonClicked
            .map { false }
        let shouldShowSearchBarCancelButton = Observable.merge(showSearchBarCancelButton, hideSearchBarCancelButton)

        // 検索文字列
        // トリムしたときに空文字になるものはスキップ
        let showResult = input.searchButtonClicked
            .withLatestFrom(input.searchBarText)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return Output(
            shouldShowSearchBarCancelButton: shouldShowSearchBarCancelButton.asDriver(onErrorDriveWith: .never()),
            makeSearchBarResignFirstResponder: input.searchBarCancelButtonClicked.asDriver(onErrorDriveWith: .never()),
            showSearchResultViewController: showResult.asDriver(onErrorDriveWith: .never())
        )
    }
}
