//
//  CollectionPaginationManipulator.swift
//  edX
//
//  Created by Muhammad Umer on 26/03/2020.
//  Copyright © 2020 edX. All rights reserved.
//

class CollectionPaginationManipulator : ScrollingPaginationViewManipulator {
    func setFooter(footer: UIView, visible: Bool) {
        
    }
    
    private let collectionView : UICollectionView

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }

    var scrollView: UIScrollView? {
        return collectionView
    }

    var canPaginate: Bool {
        return true
    }
}

extension PaginationController {
    convenience init<P: Paginator>(paginator: P, collectionView: UICollectionView) where P.Element == A {
        self.init(paginator: paginator, manipulator: CollectionPaginationManipulator(collectionView: collectionView))
    }
}
