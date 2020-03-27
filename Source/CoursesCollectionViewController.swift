//
//  CoursesTableViewController.swift
//  edX
//
//  Created by Anna Callahan on 10/15/15.
//  Copyright © 2015 edX. All rights reserved.
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
                
        let horizMargin = CourseCardCell.margin
        
        self.contentView.addSubview(courseView)
        
        courseView.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(CourseCardCell.margin)
            make.bottom.equalTo(contentView)
            make.leading.equalTo(contentView).offset(horizMargin)
            make.trailing.equalTo(contentView).offset(-horizMargin)
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

class CoursesCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
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
    private var sectionInsets: UIEdgeInsets
    
    init(environment : Environment, context: Context) {
        self.context = context
        self.environment = environment
        
        if  UIDevice.current.userInterfaceIdiom == .pad {
            sectionInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        } else {
            sectionInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.backgroundColor = OEXStyles.shared().neutralXLight()
        self.collectionView.accessibilityIdentifier = "courses-table-view"
        
        self.collectionView.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }

        collectionView.register(CourseCardCell.self, forCellWithReuseIdentifier: CourseCardCell.cellIdentifier)
        collectionView.register(EnrolledCoursesFooterView.self, forCellWithReuseIdentifier: EnrolledCoursesFooterView.identifier)
        
        self.insetsController.addSource(
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemsPerRow: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 2 : 1
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        let heightPerItem = indexPath.row == courses.count ? 100 : widthPerItem * defaultCoverImageAspectRatio
        
        return CGSize(width: widthPerItem, height: heightPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.courses.count + 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == courses.count {
            let footerCell = collectionView.dequeueReusableCell(withReuseIdentifier: EnrolledCoursesFooterView.identifier, for: indexPath as IndexPath) as! EnrolledCoursesFooterView
            footerCell.findCoursesAction = {[weak self] in
                self?.environment.router?.showCourseCatalog(fromController: self, bottomBar: nil)
            }
            return footerCell
        }
        
        let course = self.courses[indexPath.row]
        
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
            CourseCardViewModel.onCourseCatalog(course: course, wrapTitle: true).apply(card: cell.courseView, networkManager: self.environment.networkManager)
        case .EnrollmentList:
            CourseCardViewModel.onHome(course: course).apply(card: cell.courseView, networkManager: self.environment.networkManager)
        }
        cell.course = course
        
        return cell
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.insetsController.updateInsets()
    }
}

