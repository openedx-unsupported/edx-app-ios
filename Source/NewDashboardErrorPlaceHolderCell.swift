//
//  NewDashboardErrorPlaceHolderCell.swift
//  edX
//
//  Created by MuhammadUmer on 23/11/2022.
//  Copyright © 2022 edX. All rights reserved.
//

import UIKit

class NewDashboardErrorPlaceHolderCell: UITableViewCell {
    static let identifier = "NewDashboardErrorPlaceHolderCell"
    
    private lazy var label = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }
    }
    
    func setError(_ error: NSError) {
        label.text = error.description
    }
}
