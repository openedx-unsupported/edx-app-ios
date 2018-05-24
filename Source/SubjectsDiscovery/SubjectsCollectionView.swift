//
//  SubjectsCollectionView.swift
//  edX
//
//  Created by Zeeshan Arif on 5/23/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

class SubjectsCollectionView: UICollectionView, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var subjects: [Subject] = []
    private var filteredSubjects: [Subject] = []
    
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
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        print("TEST WILL DISPLAY")
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SubjectCollectionViewCell.identifier, for: indexPath) as! SubjectCollectionViewCell
        cell.configure(subject: subjects[indexPath.row])
        return cell
    }
    
    
    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SubjectCollectionViewCell.identifier, for: indexPath) as! SubjectCollectionViewCell
//        cell.configure(subject: subjects[indexPath.row])
//        return cell
//    }
    
    func filter(with string: String) {
        filteredSubjects = string == "" ? subjects : subjects.filter { $0.name.contains(find: string) }
        reloadData()
    }
    
}

class PopularSubjectsCollectionView: SubjectsCollectionView {
    
    override func loadSubjects() {
        subjects = SubjectDataModel().popularSubjects
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return subjects.count + 1
    }
    
//    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        guard indexPath.row < subjects.count - 1 else {
//            return UICollectionViewCell() // View All Subjects Cell
//        }
//        return super.collectionView(collectionView, cellForItemAt: indexPath)
//    }
}
