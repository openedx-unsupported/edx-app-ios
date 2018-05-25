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
        layout.itemSize = CGSize(width: self.view.frame.width - 2 * StandardHorizontalMargin, height: 60)
        layout.scrollDirection = .vertical
        let collectionView = SubjectsCollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.accessibilityIdentifier = "SubjectsViewController:collection-view"
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

