//
//  SubjectsCollectionView.swift
//  edX
//
//  Created by Zeeshan Arif on 5/23/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

protocol SubjectsCollectionViewDelegate: class {
    func subjectsCollectionView(_ collectionView: SubjectsCollectionView, didSelect subject: Subject)
    func didSelectViewAllSubjects(_ collectionView: SubjectsCollectionView)
}
extension SubjectsCollectionViewDelegate {
    func didSelectViewAllSubjects(_ collectionView: SubjectsCollectionView) {
        //this is a empty implementation to allow this method to be optional
    }
}

class SubjectsCollectionView: UICollectionView, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var subjects: [Subject] = [] {
        didSet {
            reloadData()
        }
    }
    
    weak var subjectsDelegate: SubjectsCollectionViewDelegate?
    
    init(with subjects: [Subject], collectionViewLayout layout: UICollectionViewLayout) {
        self.subjects = subjects
        super.init(frame: .zero, collectionViewLayout: layout)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        register(SubjectCollectionViewCell.self, forCellWithReuseIdentifier: SubjectCollectionViewCell.identifier)
        register(ViewAllSubjectsCollectionViewCell.self, forCellWithReuseIdentifier: ViewAllSubjectsCollectionViewCell.identifier)
        delegate = self
        dataSource = self
        backgroundColor = .clear
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return subjects.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SubjectCollectionViewCell.identifier, for: indexPath) as! SubjectCollectionViewCell
        cell.configure(subject: subjects[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        subjectsDelegate?.subjectsCollectionView(self, didSelect: subjects[indexPath.row])
    }
    
}

class PopularSubjectsCollectionView: SubjectsCollectionView {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return subjects.count + 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row >= subjects.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ViewAllSubjectsCollectionViewCell.identifier, for: indexPath) as! ViewAllSubjectsCollectionViewCell
            return cell
        }
        return super.collectionView(collectionView, cellForItemAt: indexPath)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row >= subjects.count {
            subjectsDelegate?.didSelectViewAllSubjects(self)
        }
        else {
            super.collectionView(collectionView, didSelectItemAt: indexPath)
        }
    }
    
}
