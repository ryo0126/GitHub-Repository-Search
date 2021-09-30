//
//  RepositoryTableViewCell.swift
//  GitHub Repository Search
//
//  Created by Ryo on 2021/10/01.
//

import UIKit

public class RepositoryTableViewCell : UITableViewCell {

    @IBOutlet public weak var titleLabel: UILabel!
    @IBOutlet public weak var descriptionLabel: UILabel!

    override public func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
    }
}
