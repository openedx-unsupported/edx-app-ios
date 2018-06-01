//
//  PopularSubjectsViewController.swift
//  edX
//
//  Created by Zeeshan Arif on 5/24/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

class PopularSubjectsViewController: UIViewController {

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "PopularSubjectsViewController:title-label"
        label.numberOfLines = 0
        let titleStyle = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralDark())
        label.attributedText = titleStyle.attributedString(withText: Strings.browseBySubject)
        return label
    }()
    
    lazy var collectionView: PopularSubjectsCollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 140, height: 60)
        layout.scrollDirection = .horizontal
        let collectionView = PopularSubjectsCollectionView(with: SubjectDataModel(), collectionViewLayout: layout)
        collectionView.accessibilityIdentifier = "PopularSubjectsViewController:collection-view"
        return collectionView
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        addSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: Setup Subviews
    private func addSubviews(){
        view.addSubview(titleLabel)
        view.addSubview(collectionView)
        setConstraints()
    }
    
    private func setConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.top.equalTo(view).offset(StandardVerticalMargin)
            make.height.equalTo(25)
        }
        
        collectionView.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel).offset(-10)
            make.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom)
            make.height.equalTo(80)
            make.bottom.equalTo(view)
        }
    }

}
