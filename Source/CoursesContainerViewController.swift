//
//  CoursesContainerViewController.swift
//  edX
//
//  Created by Muhammad Umer on 26/03/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

class CourseCardCell : UICollectionViewCell {
    
    static let margin = StandardVerticalMargin
    
    fileprivate static let cellIdentifier = "CourseCardCell"
    fileprivate let courseView = CourseCardView(frame: CGRect.zero)
    fileprivate let upgradeValuePropView = UpgradeValuePropView()
    fileprivate let containerView = UIView()
    fileprivate let bottomLine = UIView()
    fileprivate var course : OEXCourse?
    fileprivate var upgrageValuePropViewEnabled: Bool = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        courseView.applyBorderStyle(style: BorderStyle())
        contentView.backgroundColor = OEXStyles.shared().neutralXLight()
        setAccessibilityIdentifiers()
    }
    
    fileprivate func setUpView(upgrageValuePropViewEnabled: Bool) {
        self.upgrageValuePropViewEnabled = upgrageValuePropViewEnabled
        if upgrageValuePropViewEnabled {
            configureAuditCourseCardView()
        } else {
            configureVerifiedCourseCardView()
        }
    }
    
    private func configureAuditCourseCardView() {
        contentView.addSubview(containerView)
        containerView.addSubview(courseView)
        containerView.addSubview(upgradeValuePropView)
        insertSubview(bottomLine, aboveSubview: upgradeValuePropView)
        
        bottomLine.backgroundColor = OEXStyles.shared().brandAccentColor()
        upgradeValuePropView.applyBorderStyle(style: BorderStyle())
        upgradeValuePropView.backgroundColor = OEXStyles.shared().brandAccentColor()
        
        containerView.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(CourseCardCell.margin)
            make.bottom.equalTo(contentView)
            make.leading.equalTo(contentView).offset(CourseCardCell.margin)
            make.trailing.equalTo(contentView).offset(-CourseCardCell.margin)
        }
        
        courseView.snp.makeConstraints { make in
            make.top.equalTo(containerView)
            make.leading.equalTo(containerView).offset(CourseCardCell.margin)
            make.trailing.equalTo(containerView).offset(-CourseCardCell.margin)
        }
        
        bottomLine.snp.makeConstraints { make in
            make.top.equalTo(courseView.snp.bottom).offset(-4)
            make.leading.equalTo(containerView).offset(CourseCardCell.margin)
            make.trailing.equalTo(containerView).offset(-CourseCardCell.margin)
            make.height.equalTo(12)
        }
        
        upgradeValuePropView.snp.makeConstraints { make in
            make.top.equalTo(courseView.snp.bottom)
            make.leading.equalTo(containerView).offset(CourseCardCell.margin)
            make.trailing.equalTo(containerView).offset(-CourseCardCell.margin)
            make.height.equalTo(125)
        }
    }
    
    private func configureVerifiedCourseCardView() {
        contentView.addSubview(courseView)
        courseView.applyBorderStyle(style: BorderStyle())
        courseView.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(CourseCardCell.margin)
            make.bottom.equalTo(contentView)
            make.leading.equalTo(contentView).offset(CourseCardCell.margin)
            make.trailing.equalTo(contentView).offset(-CourseCardCell.margin)
            make.height.equalTo(CourseCardView.cardHeight(leftMargin: CourseCardCell.margin, rightMargin: CourseCardCell.margin))
        }
    }

    private func setAccessibilityIdentifiers() {
        contentView.accessibilityIdentifier = "CourseCardCell:content-view"
        courseView.accessibilityIdentifier = "CourseCardCell:course-card-view"
        upgradeValuePropView.accessibilityIdentifier = "CourseCardCell:course-upgrade-value-prop-view"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol CoursesContainerViewControllerDelegate : class {
    func coursesContainerChoseCourse(course : OEXCourse)
    func showUpgradeCourseDetailView()
}

class CoursesContainerViewController: UICollectionViewController {
    
    enum Context {
        case courseCatalog
        case enrollmentList
    }
    
    enum EnrollmentMode {
        case audit
        case verified
    }
    
    typealias Environment = NetworkManagerProvider & OEXRouterProvider & OEXConfigProvider & OEXInterfaceProvider & OEXAnalyticsProvider
    
    private let environment : Environment
    private let context: Context
    private var mode: EnrollmentMode = .audit
    weak var delegate : CoursesContainerViewControllerDelegate?
    var courses : [OEXCourse] = []
    private let insetsController = ContentInsetsController()
    
    private var isCourseDiscoveryEnabled: Bool {
        return environment.config.discovery.course.isEnabled
    }
    
    private var shouldShowFooter: Bool {
        return context == .enrollmentList && isCourseDiscoveryEnabled
    }
    
    private var shouldShowUpgradeValueProp: Bool {
        return mode == .audit && environment.config.isUpgradeValuePropViewEnabled
    }
    
    init(environment : Environment, context: Context) {
        self.environment = environment
        self.context = context
        
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.alwaysBounceVertical = true
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
        
        cell.upgradeValuePropView.tapAction = { [weak self] view in
            self?.environment.analytics.trackValuePropLearnMore(courseID: course.course_id ?? "", screenName: AnalyticsScreenName.CourseEnrollment)
            self?.delegate?.showUpgradeCourseDetailView()
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
        let enrollment = environment.interface?.enrollmentForCourse(withID: course.course_id)
        mode = (enrollment?.mode == "audit") ? .audit : .verified
        cell.setUpView(upgrageValuePropViewEnabled: shouldShowUpgradeValueProp)
        
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
        let upgradeValuePropHeight: CGFloat = (shouldShowUpgradeValueProp == true) ?  125 : 0
        let heightPerItem =  widthPerItem * StandardImageAspectRatio + upgradeValuePropHeight
        return CGSize(width: widthPerItem, height: heightPerItem)
    }
}
