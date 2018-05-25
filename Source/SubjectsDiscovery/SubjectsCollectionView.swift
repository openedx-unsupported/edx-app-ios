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
    func subjectsCollectionView(_ collectionView: SubjectsCollectionView, showAllSubjects: Bool )
}

class SubjectsCollectionView: UICollectionView, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var subjects: [Subject] = []
    var filteredSubjects: [Subject] = []
    weak var subjectsDelegate: SubjectsCollectionViewDelegate?
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        register(SubjectCollectionViewCell.self, forCellWithReuseIdentifier: SubjectCollectionViewCell.identifier)
        delegate = self
        dataSource = self
        loadSubjects()
        reloadData()
        backgroundColor = .clear
    }
    
    func loadSubjects() {
        subjects = SubjectDataModel().subjects
        filteredSubjects = subjects
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredSubjects.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SubjectCollectionViewCell.identifier, for: indexPath) as! SubjectCollectionViewCell
        cell.configure(subject: filteredSubjects[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        subjectsDelegate?.subjectsCollectionView(self, didSelect: filteredSubjects[indexPath.row])
    }
    
    func filter(with string: String) {
        filteredSubjects = string == "" ? subjects : subjects.filter { $0.name.contains(find: string) }
        reloadData()
    }
    
}

class PopularSubjectsCollectionView: SubjectsCollectionView {
    
    override func loadSubjects() {
        subjects = SubjectDataModel().popularSubjects
        filteredSubjects = subjects
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredSubjects.count + 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row >= filteredSubjects.count {
            
            // MARK: TODO
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SubjectCollectionViewCell.identifier, for: indexPath) as! SubjectCollectionViewCell
            cell.configure(subject: filteredSubjects[0])
            return cell
//            return UICollectionViewCell() // View All Subjects Cell
        }
        return super.collectionView(collectionView, cellForItemAt: indexPath)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row >= filteredSubjects.count {
            subjectsDelegate?.subjectsCollectionView(self, showAllSubjects: true)
        }
        else {
            super.collectionView(collectionView, didSelectItemAt: indexPath)
        }
    }
    
}
