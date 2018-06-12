//
//  PopularSubjectsViewController.swift
//  edX
//
//  Created by Zeeshan Arif on 5/24/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

protocol PopularSubjectsViewControllerDelegate: class {
    func popularSubjectsViewController(controller viewController: PopularSubjectsViewController, didSelect subject: Subject)
    func didSelectViewAllSubjects(controller viewController: PopularSubjectsViewController)
}

class PopularSubjectsViewController: UIViewController, SubjectsCollectionViewDelegate {

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "PopularSubjectsViewController:title-label"
        label.numberOfLines = 0
        let titleStyle = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralDark())
        label.attributedText = titleStyle.attributedString(withText: Strings.browseBySubject)
        return label
    }()
    
    fileprivate lazy var collectionView: PopularSubjectsCollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        let defaultMargin = SubjectCollectionViewCell.defaultMargin
        layout.sectionInset = UIEdgeInsets(top: defaultMargin, left: defaultMargin, bottom: defaultMargin, right: defaultMargin)
        layout.itemSize = CGSize(width: SubjectCollectionViewCell.defaultWidth, height: SubjectCollectionViewCell.defaultHeight)
        layout.scrollDirection = .horizontal
        let collectionView = PopularSubjectsCollectionView(with: SubjectDataModel().popularSubjects, collectionViewLayout: layout)
        collectionView.accessibilityIdentifier = "PopularSubjectsViewController:collection-view"
        collectionView.subjectsDelegate = self
        return collectionView
    }()
    
    weak var delegate: PopularSubjectsViewControllerDelegate?
    
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
            make.leading.equalTo(titleLabel).offset(-SubjectCollectionViewCell.defaultMargin)
            make.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom)
            make.height.equalTo(SubjectCollectionViewCell.defaultHeight + 2 * SubjectCollectionViewCell.defaultMargin)
            make.bottom.equalTo(view)
        }
    }
    
    func subjectsCollectionView(_ collectionView: SubjectsCollectionView, didSelect subject: Subject) {
        delegate?.popularSubjectsViewController(controller: self, didSelect: subject)
    }
    
    func didSelectViewAllSubjects(_ collectionView: SubjectsCollectionView) {
        delegate?.didSelectViewAllSubjects(controller: self)
    }
}
