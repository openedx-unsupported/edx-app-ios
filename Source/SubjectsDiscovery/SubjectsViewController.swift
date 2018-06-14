//
//  SubjectsViewController.swift
//  edX
//
//  Created by Zeeshan Arif on 5/23/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

protocol SubjectsViewControllerDelegate: class {
    func subjectsViewController(_ controller: SubjectsViewController, didSelect subject: Subject)
}

class SubjectsViewController: UIViewController, InterfaceOrientationOverriding {
    
    typealias Environment = OEXAnalyticsProvider & OEXStylesProvider
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.accessibilityIdentifier = "SubjectsViewController:search-bar"
        searchBar.placeholder = Strings.Discovery.subjectSearchBarPlaceholder
        return searchBar
    }()
    
    fileprivate lazy var collectionView: SubjectsCollectionView = {
        let collectionView = SubjectsCollectionView(with: self.subjects, collectionViewLayout: self.subjectsLayout)
        collectionView.accessibilityIdentifier = "SubjectsViewController:collection-view"
        collectionView.subjectsDelegate = self
        return collectionView
    }()
    
    fileprivate var showsCancelButton: Bool = true {
        didSet {
            searchBar.setShowsCancelButton(showsCancelButton, animated: true)
        }
    }
    fileprivate let subjects = SubjectDataModel().subjects
    weak var delegate: SubjectsViewControllerDelegate?
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
        navigationItem.title = Strings.Discovery.browseBySubject
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreen(withName: AnalyticsScreenName.SubjectsDiscovery.rawValue)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        refreshLayout()
    }
    
    private func addObservers() {
        
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
            make.leading.equalTo(searchBar)
            make.trailing.equalTo(searchBar)
            make.bottom.equalTo(safeBottom)
        }
    }
    
    func refreshLayout() {
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.collectionViewLayout = subjectsLayout
    }
    
    private var subjectsLayout: UICollectionViewLayout {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        let defaultMargin = SubjectCollectionViewCell.defaultMargin
        layout.sectionInset = UIEdgeInsets(top: defaultMargin, left: defaultMargin, bottom: defaultMargin, right: defaultMargin)
        layout.scrollDirection = .vertical
        let noOfCells: CGFloat = isVerticallyCompact() ? 3 : 2
        let itemWidth = (view.frame.width - noOfCells * 2 * defaultMargin) / noOfCells
        layout.itemSize = CGSize(width: itemWidth, height: SubjectCollectionViewCell.defaultHeight)
        return layout
    }
    
    fileprivate func hideKeyboard() {
        view.endEditing(true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue else { return }
        collectionView.snp.updateConstraints { make in
            make.bottom.equalTo(safeBottom).offset(-keyboardSize.height)
        }
    }
    
    private func keyboardWillHide(notification: NSNotification) {
        collectionView.snp.updateConstraints { make in
            make.bottom.equalTo(safeBottom)
        }
    }
    
}

extension SubjectsViewController: UISearchBarDelegate {
    
    func filter(with string: String) {
        collectionView.subjects = string.isEmpty ? subjects : subjects.filter { $0.name.lowercased().contains(find: string.lowercased()) }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filter(with: searchText)
        searchBar.accessibilityLabel = searchText.isEmpty ? Strings.Discovery.subjectSearchBarPlaceholder : searchText
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

extension SubjectsViewController: SubjectsCollectionViewDelegate {
    func subjectsCollectionView(_ collectionView: SubjectsCollectionView, didSelect subject: Subject) {
        delegate?.subjectsViewController(self, didSelect: subject)
        navigationController?.popViewController(animated: true)
    }
}

