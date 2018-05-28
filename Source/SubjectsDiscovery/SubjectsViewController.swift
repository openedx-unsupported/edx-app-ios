//
//  SubjectsViewController.swift
//  edX
//
//  Created by Zeeshan Arif on 5/23/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

class SubjectsViewController: UIViewController {

    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.accessibilityIdentifier = "SubjectsViewController:search-bar"
        return searchBar
    }()
    
    lazy var collectionView: SubjectsCollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 110, height: 60)
        layout.scrollDirection = .vertical
        let collectionView = SubjectsCollectionView(with: SubjectDataModel(), collectionViewLayout: layout)
        collectionView.accessibilityIdentifier = "SubjectsViewController:collection-view"
        collectionView.subjectsDelegate = self
        return collectionView
    }()
    
    weak var subjectsDelegate: SubjectsCollectionViewDelegate?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        addSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = Strings.browseBySubject
        collectionView.reloadData()
    }
    
    private func addSubviews() {
        view.addSubview(collectionView)
        view.addSubview(searchBar)
        setConstraints()
    }
    
    private func setConstraints() {
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(safeTop)
            make.leading.equalTo(safeLeading)
            make.trailing.equalTo(safeTrailing)
            make.bottom.equalTo(collectionView.snp.top)
        }
        
        collectionView.snp.makeConstraints { make in
            make.leading.equalTo(safeLeading)
            make.trailing.equalTo(safeTrailing)
            make.bottom.equalTo(safeBottom)
        }
    }
    
}

extension SubjectsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        collectionView.filter(with: searchText)
    }
}

extension SubjectsViewController: SubjectsCollectionViewDelegate {
    func subjectsCollectionView(_ collectionView: SubjectsCollectionView, didSelect subject: Subject) {
        subjectsDelegate?.subjectsCollectionView(collectionView, didSelect: subject)
        navigationController?.popViewController(animated: true)
    }
}

