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
    
    fileprivate var dataModel: SubjectDataModel?
    fileprivate var subjects: [Subject] = []
    var filteredSubjects: [Subject] = []
    weak var subjectsDelegate: SubjectsCollectionViewDelegate?
    
    init(with dataModel: SubjectDataModel, collectionViewLayout layout: UICollectionViewLayout) {
        self.dataModel = dataModel
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
        loadSubjects()
        backgroundColor = .clear
    }
    
    func loadSubjects() {
        guard let dataModel = dataModel else { return }
        subjects = dataModel.subjects
        filteredSubjects = subjects
        reloadData()
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
        filteredSubjects = string.isEmpty ? subjects : subjects.filter { $0.name.lowercased().contains(find: string.lowercased()) }
        reloadData()
    }
    
}

class PopularSubjectsCollectionView: SubjectsCollectionView {
    
    override func loadSubjects() {
        guard let dataModel = dataModel else { return }
        subjects = dataModel.popularSubjects
        filteredSubjects = subjects
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredSubjects.count + 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row >= filteredSubjects.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ViewAllSubjectsCollectionViewCell.identifier, for: indexPath) as! ViewAllSubjectsCollectionViewCell
            return cell
        }
        return super.collectionView(collectionView, cellForItemAt: indexPath)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row >= filteredSubjects.count {
            subjectsDelegate?.didSelectViewAllSubjects(self)
        }
        else {
            super.collectionView(collectionView, didSelectItemAt: indexPath)
        }
    }
    
}
