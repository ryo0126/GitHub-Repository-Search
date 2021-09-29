//
//  SearchRepositoryViewController.swift
//  GitHub Repository Search
//
//  Created by Ryo on 2021/09/28.
//

import UIKit
import RxSwift

class SearchRepositoryViewController: UIViewController {

    /// Safe Areaの外側を塗るためのView
    @IBOutlet private weak var barFiller: UIView!
    private weak var searchBar: UISearchBar!

    private let disposeBag = DisposeBag()

    private let viewModel: SearchRepositoryViewModel<SearchRepositoryUseCase> = {
        let useCase = SearchRepositoryUseCase()
        let viewModel = SearchRepositoryViewModel(useCase: useCase)
        return viewModel
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }

    private func setupUI() {
        // サーチバー設定
        guard let navigationBarFrame = navigationController?.navigationBar.bounds else { fatalError() }
        let searchBar = UISearchBar(frame: navigationBarFrame)
        searchBar.placeholder = "Repository Keyword"
        // 背景色を塗りつぶしようのViewと同じにする
        searchBar.backgroundColor = barFiller.backgroundColor
        navigationItem.titleView = searchBar
        navigationItem.titleView?.frame = searchBar.frame
        self.searchBar = searchBar
    }

    private func setupBindings() {
        let output = viewModel.transform(SearchRepositoryViewModel.Input(
            searchBarDidBeginEditing: searchBar.rx.textDidBeginEditing.asObservable(),
            searchBarCancelButtonClicked: searchBar.rx.cancelButtonClicked.asObservable(),
            searchBarText: searchBar.rx.text.orEmpty.asObservable(),
            searchButtonClicked: searchBar.rx.searchButtonClicked.asObservable()
        ))

        // キャンセルボタンを表示するかどうか
        output.shouldShowSearchBarCancelButton
            .drive(onNext: { [unowned self] in
                self.searchBar.showsCancelButton = $0
            })
            .disposed(by: disposeBag)
        // サーチバーのフォーカスを外す
        output.makeSearchBarResignFirstResponder
            .drive(onNext: { [unowned self] in
                self.searchBar.resignFirstResponder()
            })
            .disposed(by: disposeBag)
        // 検索結果画面へ遷移
        output.showSearchResultViewController
            .drive(onNext: {
                // TODO: 検索結果画面へ遷移
                print("Search for \($0)")
            })
            .disposed(by: disposeBag)
    }
}
