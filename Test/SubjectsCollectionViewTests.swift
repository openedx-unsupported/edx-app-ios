//
//  SubjectsCollectionViewTests.swift
//  edXTests
//
//  Created by Zeeshan Arif on 5/28/18.
//  Copyright © 2018 edX. All rights reserved.
//

@testable import edX

class SubjectsCollectionViewTests: XCTestCase {
    
    func testFilterSubjects() {
        let dataModel = SubjectDataModel(fileName: "TestSubjects")
        let collectionView = SubjectsCollectionView(with: dataModel, collectionViewLayout: UICollectionViewLayout())
        collectionView.filter(with: "Test 1")
        XCTAssertEqual(collectionView.filteredSubjects.count, 2)
    }
    
}
