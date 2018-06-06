//
//  SubjectsViewController.swift
//  edX
//
//  Created by Zeeshan Arif on 5/23/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

class SubjectsViewController: UIViewController {
    
    typealias Environment = OEXAnalyticsProvider & OEXStylesProvider
    
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.accessibilityIdentifier = "SubjectsViewController:search-bar"
        searchBar.placeholder = Strings.subjectSearchBarPlaceholder
        return searchBar
    }()
    
    lazy var collectionView: SubjectsCollectionView = {
        let collectionView = SubjectsCollectionView(with: SubjectDataModel(), collectionViewLayout: self.subjectsLayout)
        collectionView.accessibilityIdentifier = "SubjectsViewController:collection-view"
        collectionView.subjectsDelegate = self
        return collectionView
    }()
    
    fileprivate var showsCancelButton: Bool = true {
        didSet {
            searchBar.setShowsCancelButton(showsCancelButton, animated: true)
        }
    }
    
    weak var subjectsDelegate: SubjectsCollectionViewDelegate?
    private let environment: Environment
    
    init(environment: Environment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
        addObservers()
        addSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = environment.styles.neutralWhite()
        navigationItem.title = Strings.browseBySubject
        collectionView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreen(withName: AnalyticsScreenName.SubjectsDiscovery.rawValue)
    }
    
    private func addObservers() {
        
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.UIDeviceOrientationDidChange.rawValue) { [weak self] (_, _, _) in
            self?.refreshLayout()
        }
        
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.UIKeyboardWillShow.rawValue) { [weak self] (notification, _, _) in
            self?.keyboardWillShow(notification: notification)
        }
        
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.UIKeyboardWillHide.rawValue) { [weak self] (notification, _, _) in
            self?.keyboardWillHide(notification: notification)
        }
        
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
    
    func refreshLayout() {
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.collectionViewLayout = subjectsLayout
    }
    
    private var subjectsLayout: UICollectionViewLayout {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.scrollDirection = .vertical
        let noOfCells: CGFloat = isVerticallyCompact() ? 3 : 2
        let itemWidth = (view.frame.width - noOfCells * 20) / noOfCells
        layout.itemSize = CGSize(width: itemWidth, height: SubjectCollectionViewCell.defaultHeight)
        return layout
    }
    
    fileprivate func hideKeyboard() {
        view.endEditing(true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

extension SubjectsViewController: InterfaceOrientationOverriding {
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
}

extension SubjectsViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        collectionView.filter(with: searchText)
        searchBar.accessibilityLabel = searchText.isEmpty ? Strings.subjectSearchBarPlaceholder : searchText
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        showsCancelButton = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        hideKeyboard()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        hideKeyboard()
    }
}

// MARK: Keyboard Handling
extension SubjectsViewController {
    fileprivate func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            collectionView.snp.updateConstraints { make in
                make.bottom.equalTo(safeBottom).offset(-keyboardSize.height)
            }
        }
    }
    
    fileprivate func keyboardWillHide(notification: NSNotification) {
        collectionView.snp.updateConstraints { make in
            make.bottom.equalTo(safeBottom)
        }
    }
}

extension SubjectsViewController: SubjectsCollectionViewDelegate {
    func subjectsCollectionView(_ collectionView: SubjectsCollectionView, didSelect subject: Subject) {
        hideKeyboard()
        subjectsDelegate?.subjectsCollectionView(collectionView, didSelect: subject)
        navigationController?.popViewController(animated: true)
    }
}

