//
//  CourseCertificateCell.swift
//  edX
//
//  Created by Michael Katz on 11/12/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

class CourseCertificateCell: UITableViewCell {

    static let identifier = "CourseCertificateCellIdentifier"
    private let certificateView = CourseCertificateView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configureViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        self.backgroundColor =  OEXStyles.shared().neutralXLight()

        applyStandardSeparatorInsets()
        contentView.addSubview(certificateView)
        certificateView.snp_makeConstraints(closure: { (make) -> Void in
            make.edges.equalTo(contentView)
        })
    }

    func useItem(item: CertificateDashboardItem) {
        certificateView.certificateItem = item.certificateItem
    }
}
