//
//  CourseCatalogDetailView.swift
//  edX
//
//  Created by Akiva Leffert on 12/7/15.
//  Copyright © 2015 edX. All rights reserved.
//

private let margin : CGFloat = 20

import WebKit
import edXCore

class CourseCatalogDetailView : UIView {

    fileprivate struct Field {
        let name : String
        let value : String
        let icon : Icon
    }
    
    typealias Environment = NetworkManagerProvider & OEXStylesProvider & OEXAnalyticsProvider
    
    fileprivate let environment : Environment
    
    let courseCard = CourseCardView()
    fileprivate let blurbLabel = UILabel()
    private let actionButton = SpinnerButton(type: .system)
    private let container : TZStackView
    private let insetContainer : TZStackView
    private let descriptionView = WKWebView()
    fileprivate let fieldsList = TZStackView()
    fileprivate let playButton = UIButton(type: .system)
    
    let insetsController = ContentInsetsController()
    // used to offset the overview webview content which is at the bottom
    // below the rest of the content
    private let topContentInsets = ConstantInsetsSource(insets: .zero, affectsScrollIndicators: false)
    
    var action: ((_ completion : @escaping () -> Void) -> Void)?
    
    private var _loaded = Sink<()>()
    var loaded : OEXStream<()> {
        return _loaded
    }
    
    init(frame: CGRect, environment: Environment) {
        self.insetContainer = TZStackView(arrangedSubviews: [blurbLabel, actionButton, fieldsList])
        self.container = TZStackView(arrangedSubviews: [courseCard, insetContainer])
        self.environment = environment
        
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        addSubview(descriptionView)
        descriptionView.scrollView.addSubview(container)
        descriptionView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        container.snp.makeConstraints { make in
            make.top.equalTo(descriptionView)
            make.leading.equalTo(descriptionView)
            make.trailing.equalTo(descriptionView)
        }

        courseCard.snp.makeConstraints { make in
            make.height.equalTo(CourseCardView.cardHeight())
        }

        container.spacing = margin
        for stack in [container, fieldsList, insetContainer] {
            stack.axis = .vertical
            stack.alignment = .fill
        }
        
        insetContainer.layoutMarginsRelativeArrangement = true
        insetContainer.layoutMargins = UIEdgeInsets.init(top: 0, left: margin, bottom: 0, right: margin)
        insetContainer.spacing = margin
        
        insetsController.addSource(source: topContentInsets)
        
        fieldsList.layoutMarginsRelativeArrangement = true
        
        blurbLabel.numberOfLines = 0
        
        actionButton.oex_addAction({[weak self] _ in
            self?.actionButton.showProgress = true
            self?.action?( {[weak self] in
                            self?.actionButton.showProgress = false
            } )
            }, for: .touchUpInside)
        
        descriptionView.scrollView.decelerationRate = UIScrollView.DecelerationRate.normal
        descriptionView.navigationDelegate = self
        descriptionView.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        
        playButton.setImage(Icon.CourseVideoPlay.imageWithFontSize(size: 60), for: .normal)
        playButton.tintColor = OEXStyles.shared().neutralWhite()
        playButton.layer.shadowOpacity = 0.5
        playButton.layer.shadowRadius = 3
        playButton.layer.shadowOffset = CGSize.zero
        courseCard.addCenteredOverlay(view: playButton)

        descriptionView.scrollView.oex_addObserver(observer: self, forKeyPath: "bounds") { (observer, scrollView, _) -> Void in
            let offset = scrollView.contentOffset.y + scrollView.contentInset.top
            // Even though it's in the webview's scrollview,
            // the container view doesn't offset when the content scrolls.
            // As such, we manually offset it here
            observer.container.transform = CGAffineTransform(translationX: 0, y: -offset)
        }
    }
    
    func setupInController(controller: UIViewController) {
        insetsController.setupInController(owner: controller, scrollView: descriptionView.scrollView)
    }
    
    private var blurbStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralXDark())
    }
    
    private var descriptionHeaderStyle : OEXTextStyle {
        return OEXTextStyle(weight: .bold, size: .large, color: OEXStyles.shared().neutralXDark())
    }
    
    private func fieldSeparator() -> UIView {
        let view = UIView()
        view.backgroundColor = OEXStyles.shared().neutralLight()
        view.snp.makeConstraints { make in
            make.height.equalTo(OEXStyles.dividerSize())
        }
        return view
    }
    
    var blurbText : String? {
        didSet {
            if let blurb = blurbText, !blurb.isEmpty {
                self.blurbLabel.attributedText = blurbStyle.attributedString(withText: blurb)
                self.blurbLabel.isHidden = false
            }
            else {
                self.blurbLabel.isHidden = true
            }
        }
    }
    
    var descriptionHTML : String? {
        didSet {
            guard let html = OEXStyles.shared().styleHTMLContent(descriptionHTML, stylesheet: "inline-content") else {
                self.descriptionView.loadHTMLString("", baseURL: environment.networkManager.baseURL)
                return
            }
            
            self.descriptionView.loadHTMLString(html, baseURL: environment.networkManager.baseURL)
        }
    }
    
    fileprivate var fields : [Field] = [] {
        didSet {
            for view in self.fieldsList.arrangedSubviews {
                view.removeFromSuperview()
            }
            let views = fields.map{ viewForField(field: $0) }.interpose { fieldSeparator() }
            
            for view in views {
                fieldsList.addArrangedSubview(view)
            }
        }
    }
    
    private func viewForField(field : Field) -> UIView {
        let view = ChoiceLabel()
        view.titleText = field.name
        view.valueText = field.value
        view.icon = field.icon
        return view
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.topContentInsets.currentInsets = UIEdgeInsets(top: self.container.frame.height + StandardVerticalMargin, left: 0, bottom: 0, right: 0)
    }
    
    var actionText: String? {
        get {
            return self.actionButton.attributedTitle(for: .normal)?.string
        }
        set {
            actionButton.applyButtonStyle(style: OEXStyles.shared().filledEmphasisButtonStyle, withTitle: newValue)
        }
    }
    
    var invitationOnlyText: String? {
        get {
            return actionButton.attributedTitle(for: .normal)?.string
        }
        set {
            actionButton.applyButtonStyle(style: environment.styles.filledButtonStyle(color: environment.styles.neutralBase()), withTitle: newValue)
            actionButton.isEnabled = false
        }
    }
}

extension CourseCatalogDetailView {
    
    private func fieldsForCourse(course : OEXCourse) -> [Field] {
        var result : [Field] = []
        if let effort = course.effort, !effort.isEmpty {
            result.append(Field(name: Strings.CourseDetail.effort, value: effort, icon: .CourseEffort))
        }
        if let endDate = course.end, !course.isStartDateOld {
            let date = DateFormatting.format(asMonthDayYearString: endDate as NSDate)
            result.append(Field(name: Strings.CourseDetail.endDate, value: date ?? "", icon: .CourseEnd))
        }
        return result
    }
    
    func applyCourse(course : OEXCourse) {
        CourseCardViewModel.onCourseCatalog(course: course, wrapTitle: true).apply(card: courseCard, networkManager: self.environment.networkManager)
        self.blurbText = course.short_description
        self.descriptionHTML = course.overview_html
        let fields = fieldsForCourse(course: course)
        self.fields = fields
        self.playButton.isHidden = course.courseVideoMediaInfo?.uri?.isEmpty ?? true
        self.playButton.oex_removeAllActions()
        self.playButton.oex_addAction(
            {[weak self] _ in
                if let
                    path = course.courseVideoMediaInfo?.uri,
                    let url = NSURL(string: path, relativeTo: self?.environment.networkManager.baseURL)
                {
                    UIApplication.shared.openURL(url as URL)
                }
            }, for: .touchUpInside)
    }
}

extension CourseCatalogDetailView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        setNeedsLayout()
        layoutIfNeeded()
        webView.scrollView.contentOffset = CGPoint(x: 0, y: -webView.scrollView.contentInset.top)
        _loaded.send(())
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType != .other {
            if let URL = navigationAction.request.url, UIApplication.shared.canOpenURL(URL){
                UIApplication.shared.openURL(URL)
            }
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }
}

// Testing
extension CourseCatalogDetailView {
    var t_showingEffort : Bool {
        return self.fields.contains {(field : Field) in field.icon == .CourseEffort }
    }
    
    var t_showingEndDate : Bool {
        return self.fields.contains {(field : Field) in field.icon == .CourseEnd }
    }
    
    var t_showingPlayButton : Bool {
        return !self.playButton.isHidden
    }
    
    var t_showingShortDescription : Bool {
        return !self.blurbLabel.isHidden
    }
}

