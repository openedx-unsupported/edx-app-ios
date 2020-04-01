//
//  CoursesCollectionViewController.swift
//  edX
//
//  Created by Anna Callahan on 10/15/15.
//  Copyright © 2015 edX. All rights reserved.
//
//  Created by Muhammad Umer on 26/03/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

class CourseCardCell : UICollectionViewCell {
    static let margin = StandardVerticalMargin
    
    fileprivate static let cellIdentifier = "CourseCardCell"
    fileprivate let courseView = CourseCardView(frame: CGRect.zero)
    fileprivate var course : OEXCourse?
    private let courseCardBorderStyle = BorderStyle()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let horizontalMargin = CourseCardCell.margin
        
        contentView.addSubview(courseView)
        
        courseView.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(CourseCardCell.margin)
            make.bottom.equalTo(contentView)
            make.leading.equalTo(contentView).offset(horizontalMargin)
            make.trailing.equalTo(contentView).offset(-horizontalMargin)
            make.height.equalTo(CourseCardView.cardHeight(leftMargin: CourseCardCell.margin, rightMargin: CourseCardCell.margin))
        }
        
        courseView.applyBorderStyle(style: courseCardBorderStyle)
        
        contentView.backgroundColor = OEXStyles.shared().neutralXLight()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol CoursesCollectionViewControllerDelegate : class {
    func coursesTableChoseCourse(course : OEXCourse)
}

class CoursesCollectionViewController: UICollectionViewController {
    
    enum Context {
        case CourseCatalog
        case EnrollmentList
    }
    
    typealias Environment = NetworkManagerProvider & OEXRouterProvider
    
    private let environment : Environment
    private let context: Context
    
    weak var delegate : CoursesCollectionViewControllerDelegate?
    var courses : [OEXCourse] = []
    let insetsController = ContentInsetsController()
    
    init(environment : Environment, context: Context) {
        self.environment = environment
        self.context = context
        
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = OEXStyles.shared().neutralXLight()
        collectionView.accessibilityIdentifier = "courses-table-view"
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
        
        collectionView.register(CourseCardCell.self, forCellWithReuseIdentifier: CourseCardCell.cellIdentifier)
        collectionView.register(EnrolledCoursesFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: EnrolledCoursesFooterView.identifier)
        
        insetsController.addSource(
            source: ConstantInsetsSource(insets: UIEdgeInsets(top: 0, left: 0, bottom: StandardVerticalMargin, right: 0), affectsScrollIndicators: false)
        )
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(
            alongsideTransition: { [weak self] _ in
                self?.collectionView.collectionViewLayout.invalidateLayout()
            },
            completion: { _ in }
        )
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return courses.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.size.height, height: EnrolledCoursesFooterViewHeight)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: EnrolledCoursesFooterView.identifier, for: indexPath) as! EnrolledCoursesFooterView
            footerView.findCoursesAction = {[weak self] in
                self?.environment.router?.showCourseCatalog(fromController: self, bottomBar: nil)
            }
            return footerView
        }
        
        return UICollectionReusableView()
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let course = courses[indexPath.row]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CourseCardCell.cellIdentifier, for: indexPath as IndexPath) as! CourseCardCell
        DispatchQueue.main.async {
            cell.accessibilityLabel = cell.courseView.updateAcessibilityLabel()
        }
        cell.accessibilityHint = Strings.accessibilityShowsCourseContent
        cell.courseView.tapAction = { [weak self] card in
            self?.delegate?.coursesTableChoseCourse(course: course)
        }
        
        switch context {
        case .CourseCatalog:
            CourseCardViewModel.onCourseCatalog(course: course, wrapTitle: true).apply(card: cell.courseView, networkManager: environment.networkManager)
        case .EnrollmentList:
            CourseCardViewModel.onHome(course: course).apply(card: cell.courseView, networkManager: environment.networkManager)
        }
        cell.course = course
        
        return cell
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        insetsController.updateInsets()
    }
}

extension CoursesCollectionViewController: UICollectionViewDelegateFlowLayout {
    fileprivate var sectionInsets: UIEdgeInsets {
        return .zero
    }
    
    fileprivate var itemsPerRow: CGFloat {
        return UIDevice.current.userInterfaceIdiom == .pad ? 2 : 1
    }
    
    fileprivate var minimumSpace: CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return minimumSpace
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return minimumSpace
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let widthPerItem = view.frame.width / itemsPerRow
        let heightPerItem = widthPerItem * defaultCoverImageAspectRatio
        
        return CGSize(width: widthPerItem, height: heightPerItem)
    }
}
