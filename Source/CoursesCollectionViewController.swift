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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
                
        contentView.addSubview(courseView)
        
        courseView.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(CourseCardCell.margin)
            make.bottom.equalTo(contentView)
            make.leading.equalTo(contentView).offset(CourseCardCell.margin)
            make.trailing.equalTo(contentView).offset(-CourseCardCell.margin)
            make.height.equalTo(CourseCardView.cardHeight(leftMargin: CourseCardCell.margin, rightMargin: CourseCardCell.margin))
        }
        
        courseView.applyBorderStyle(style: BorderStyle())
        
        contentView.backgroundColor = OEXStyles.shared().neutralXLight()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol CoursesContainerViewControllerDelegate : class {
    func coursesContainerChoseCourse(course : OEXCourse)
}

class CoursesContainerViewController: UICollectionViewController {
    
    enum Context {
        case courseCatalog
        case enrollmentList
    }
    
    typealias Environment = NetworkManagerProvider & OEXRouterProvider & OEXConfigProvider
    
    private let environment : Environment
    private let context: Context
    
    weak var delegate : CoursesContainerViewControllerDelegate?
    var courses : [OEXCourse] = []
    private let insetsController = ContentInsetsController()
    
    private var isCourseDiscoveryEnabled: Bool {
        return environment.config.discovery.course.isEnabled
    }
    
    private var shouldShowFooter: Bool {
        return context == .enrollmentList && isCourseDiscoveryEnabled
    }
    
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
        collectionView.accessibilityIdentifier = "courses-container-view"
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view)
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
        return CGSize(width: collectionView.frame.size.width, height: shouldShowFooter ? EnrolledCoursesFooterViewHeight : 0)
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
            self?.delegate?.coursesContainerChoseCourse(course: course)
        }
        
        switch context {
        case .courseCatalog:
            CourseCardViewModel.onCourseCatalog(course: course, wrapTitle: true).apply(card: cell.courseView, networkManager: environment.networkManager)
            break
        case .enrollmentList:
            CourseCardViewModel.onHome(course: course).apply(card: cell.courseView, networkManager: environment.networkManager)
            break
        }
        cell.course = course
        
        return cell
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        insetsController.updateInsets()
    }
}

extension CoursesContainerViewController: UICollectionViewDelegateFlowLayout {
    private var sectionInsets: UIEdgeInsets {
        return .zero
    }
    
    private var itemsPerRow: CGFloat {
        return UIDevice.current.userInterfaceIdiom == .pad ? 2 : 1
    }
    
    private var minimumSpace: CGFloat {
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
        let heightPerItem = widthPerItem * StandardImageAspectRatio
        
        return CGSize(width: widthPerItem, height: heightPerItem)
    }
}
