//
//  SearchResultViewModel.swift
//  GitHub Repository Search
//
//  Created by Ryo on 2021/09/30.
//

import RxSwift
import RxCocoa
import RxRelay
import RxSwiftExt

public class SearchResultViewModel<U : SearchResultUseCaseProtocol>  : ViewModel {

    public struct Input {

        /// viewWillAppear
        var viewWillAppear: Observable<Void>
        /// 引っ張って更新
        var didRefreshRepositoryTable: Observable<Void>
        /// 一番下までスクロールした
        var didScrollToBottom: Observable<Void>
    }

    public struct Output {
        
        /// ナビゲーションバーのタイトル
        var navigationTitle: Driver<String>
        /// 最初のロード画面を隠す
        var hideInitialLoadingView: Driver<Void>
        /// 引っ張って更新状態を終える
        var endRefreshing: Driver<Void>
        /// テーブルを操作可能にするか
        var shouldEnableTableViewUserInteractive: Driver<Bool>
        /// エラー画面を表示するか
        var shouldShowErrorView: Driver<Bool>
        /// 流すレポジトリのデータ
        var repositories: Observable<[Repository]>
    }

    public typealias ViewInput = Input
    public typealias ViewOutput = Output

    /// 一ページあたりのレポジトリ表示数
    private let repositoryCountPerPage: Int = 50

    /// 渡された検索文字列
    private let query: String
    private let useCase: U

    /// 表示しているページ番号
    private let currentPage = BehaviorRelay<Int>(value: 1)
    /// 現在表示しているレポジトリ
    private let currentRepositories = BehaviorRelay<[Repository]>(value: [])
    /// 次のページを読み込み中かどうか
    private let isLoadingRepositoriesOfNextPage = BehaviorRelay<Bool>(value: false)

    private let disposeBag = DisposeBag()

    public init(query: String, useCase: U) {
        self.query = query
        self.useCase = useCase
    }

    public func transform(_ input: Input) -> Output {
        let viewWillAppearForTheFirstTime = input.viewWillAppear
            .take(1)
            .share()

        // ナビゲーションタイトルは一度表示すればいいので初回だけイベントを受け取る
        let navigationTitle = viewWillAppearForTheFirstTime
            .map { [unowned self] _ in self.query }

        let beginReloading = Observable.merge(
            viewWillAppearForTheFirstTime,
            input.didRefreshRepositoryTable
        ).share()

        // リロードを始めたらページ番号は1にリセット
        beginReloading
            .map { _ in 1 }
            .bind(to: currentPage)
            .disposed(by: disposeBag)

        let tryToReloadRepositories = beginReloading
            .flatMapLatest { [unowned self] _ in
                // 失敗しうるのでmaterializeする
                // リロード時は必ず1ページ目を読み込む
                self.useCase.searchRepositories(for: self.query, countPerPage: self.repositoryCountPerPage, in: 1)
                    .materialize()
            }
            .share()
        let repositories = tryToReloadRepositories
            .elements()
            .share()
        // 現在表示中のレポジトリにリロード時のレポジトリをバインド
        repositories
            .bind(to: currentRepositories)
            .disposed(by: disposeBag)

        let endReloading = repositories
            .mapToVoid()
            .share()

        let endRefreshing = endReloading
        // 初回ロードが終わったら最初のロード画面を消す
        // (1回走ればいいのでtake(1))
        let hideInitialLoadingView = endReloading
            .take(1)

        // リロードが始まったらテーブルを操作不能にする
        let enableTableViewUserInteractive = beginReloading
            .map { _ in false }
        // リロードが終わったらテーブルを操作可能にする
        let disableTableViewUserInteractive = endReloading
            .map { _ in true }
        let shouldEnableTableViewUserInteractive = Observable.merge(enableTableViewUserInteractive, disableTableViewUserInteractive)

        // 一番下までスクロールしたら次ページ読み込み準備
        input.didScrollToBottom
            .filter { [unowned self] in !self.isLoadingRepositoriesOfNextPage.value }
            // いっぱい流れる可能性があるのでフィルタ
            .debounce(.milliseconds(250), scheduler: MainScheduler.instance)
            .map { _ in true }
            .bind(to: isLoadingRepositoriesOfNextPage)
            .disposed(by: disposeBag)
        // ロード開始したらページ番号を進める
        isLoadingRepositoriesOfNextPage
            .filter { $0 }
            .map { [unowned self] _ in self.currentPage.value + 1 }
            .bind(to: currentPage)
            .disposed(by: disposeBag)

        let tryToLoadRepositoriesOfNextPage = currentPage
            // 1ページ目は流さない(リロード処理とかぶるため)
            .filter { $0 > 1 }
            .flatMapLatest { [unowned self] in
                // 失敗しうるのでmaterializeする
                self.useCase.searchRepositories(for: self.query, countPerPage: self.repositoryCountPerPage, in: $0)
                    .materialize()
            }
            .share()
        let didLoadRepositoriesOfNextPage = tryToLoadRepositoriesOfNextPage
            .elements()
            .share()
        // 新しいページを読んだら前の分と合成
        didLoadRepositoriesOfNextPage
            .map { [unowned self] in self.currentRepositories.value + $0 }
            .bind(to: currentRepositories)
            .disposed(by: disposeBag)
        // 新しいページを読んだらロード状態をオフにする
        didLoadRepositoriesOfNextPage
            .mapToVoid()
            // すぐに次ページロード可能状態にならないように遅延する
            .delay(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { _ in false }
            .bind(to: isLoadingRepositoriesOfNextPage)
            .disposed(by: disposeBag)

        // リロードおよび次ページ取得に失敗したらエラー表示
        let showErrorView = Observable.merge(
            tryToReloadRepositories.errors(),
            tryToLoadRepositoriesOfNextPage.errors()
        ).mapToVoid()
        // 何らかのレポジトリデータが取れたらエラー非表示
        let hideErrorView = currentRepositories
            .asObservable()
            .mapToVoid()
        let shouldShowErrorView = Observable.merge(
            // 最初はエラーなしなのでviweWillAppearでは非表示を流す
            viewWillAppearForTheFirstTime.map { _ in false },
            showErrorView.map { _ in true },
            hideErrorView.map { _ in false }
        )

        return Output(
            navigationTitle: navigationTitle.asDriver(onErrorDriveWith: .never()),
            hideInitialLoadingView: hideInitialLoadingView.asDriver(onErrorDriveWith: .never()),
            endRefreshing: endRefreshing.asDriver(onErrorDriveWith: .never()),
            shouldEnableTableViewUserInteractive: shouldEnableTableViewUserInteractive.asDriver(onErrorDriveWith: .never()),
            shouldShowErrorView: shouldShowErrorView.asDriver(onErrorDriveWith: .never()),
            repositories: currentRepositories.asObservable()
        )
    }
}
