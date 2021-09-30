//
//  SearchResultViewController.swift
//  GitHub Repository Search
//
//  Created by Ryo on 2021/09/30.
//

import UIKit
import RxSwift
import RxRelay
import SnapKit

class SearchResultViewController: UIViewController {

    @IBOutlet private weak var indicatorWrapper: UIView!
    @IBOutlet private weak var indicator: UIActivityIndicatorView!
    @IBOutlet private weak var barFiller: UIView!
    @IBOutlet private weak var repositoryTableView: UITableView!
    @IBOutlet private weak var errorView: UIView!
    private weak var refreshControl: UIRefreshControl!

    private let didRefreshRepositoryTable = PublishRelay<Void>()
    private let didScrollToBottom = PublishRelay<Void>()
    private let disposeBag = DisposeBag()

    private let viewModel: SearchResultViewModel<SearchResultUseCase<RestGitHubRepository>>

    init?(coder: NSCoder, searchQuery: String) {
        let repository = RestGitHubRepository()
        let useCase = SearchResultUseCase(repository: repository)
        viewModel = SearchResultViewModel(query: searchQuery, useCase: useCase)

        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        // IBからは使わない
        fatalError("Not Implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }

    private func setupUI() {
        // テーブルビュー
        repositoryTableView.register(
            UINib(nibName: String(describing: RepositoryTableViewCell.self), bundle: nil),
            forCellReuseIdentifier: String(describing: RepositoryTableViewCell.self)
        )
        repositoryTableView.delegate = self
        repositoryTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 48, right: 0)
        // 引っ張って更新
        let refreshControl = UIRefreshControl()
        repositoryTableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(didRefreshRepositoryTable(_:)), for: .valueChanged)
        self.refreshControl = refreshControl
    }

    private func setupBindings() {
        let output = viewModel.transform(SearchResultViewModel.Input(
            viewWillAppear: self.rx.sentMessage(#selector(self.viewWillAppear(_:))).mapToVoid(),
            didRefreshRepositoryTable: didRefreshRepositoryTable.asObservable(),
            didScrollToBottom: didScrollToBottom.asObservable()
        ))

        output.navigationTitle
            .drive(onNext: { [unowned self] title in
                self.navigationItem.title = title
            })
            .disposed(by: disposeBag)

        output.hideInitialLoadingView
            .drive(onNext: { [unowned self] _ in
                // ゆっくり消す
                UIView.animate(withDuration: 0.125) { [weak self] in
                    guard let self = self else { return }
                    self.indicatorWrapper.alpha = 0
                }
                self.indicator.stopAnimating()
            })
            .disposed(by: disposeBag)

        output.endRefreshing
            .drive(onNext: { [unowned self] _ in
                self.refreshControl.endRefreshing()
            })
            .disposed(by: disposeBag)

        output.shouldEnableTableViewUserInteractive
            .drive(onNext: { [unowned self] enabled in
                self.repositoryTableView.isUserInteractionEnabled = enabled
            })
            .disposed(by: disposeBag)

        output.shouldShowErrorView
            .drive(onNext: { [unowned self] shouldShow in
                // ゆっくり表示切り替え
                UIView.animate(withDuration: 0.125) { [weak self] in
                    guard let self = self else { return }
                    self.errorView.alpha = shouldShow ? 1.0 : 0.0
                }
            })
            .disposed(by: disposeBag)

        output.repositories
            .bind(to: repositoryTableView.rx.items(
                cellIdentifier: String(describing: RepositoryTableViewCell.self),
                cellType: RepositoryTableViewCell.self)
            ) { row, element, cell in
                cell.titleLabel?.text = element.name

                // decriptionがなかったらイタリックにする
                let fontSize = cell.descriptionLabel.font.pointSize
                if let description = element.description {
                    cell.descriptionLabel?.font = .systemFont(ofSize: fontSize)
                    cell.descriptionLabel?.text = description
                } else {
                    cell.descriptionLabel?.font = .italicSystemFont(ofSize: fontSize)
                    cell.descriptionLabel?.text = "(No description)"
                }
            }
            .disposed(by: disposeBag)
    }

    @objc
    private func didRefreshRepositoryTable(_ sender: UIRefreshControl) {
        // イベントを流す
        didRefreshRepositoryTable.accept(())
    }
}

extension SearchResultViewController : UITableViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 一番下にスクロールした判定(いっぱい流れるのでViewModel側でdebounceするなどしてフィルタすること)
        if repositoryTableView.contentOffset.y + repositoryTableView.frame.size.height > repositoryTableView.contentSize.height && repositoryTableView.isDragging {
            didScrollToBottom.accept(())
        }
    }
}
