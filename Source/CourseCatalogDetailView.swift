//
//  CourseCatalogDetailView.swift
//  edX
//
//  Created by Akiva Leffert on 12/7/15.
//  Copyright © 2015 edX. All rights reserved.
//

private let margin : CGFloat = 20

import edXCore

class CourseCatalogDetailView : UIView, UIWebViewDelegate {

    private struct Field {
        let name : String
        let value : String
        let icon : Icon
    }
    
    typealias Environment = NetworkManagerProvider
    
    private let environment : Environment
    
    private let courseCard = CourseCardView()
    private let blurbLabel = UILabel()
    private let actionButton = SpinnerButton(type: .System)
    private let container : TZStackView
    private let insetContainer : TZStackView
    private let descriptionView = UIWebView()
    private let fieldsList = TZStackView()
    private let playButton = UIButton(type: .System)
    
    let insetsController = ContentInsetsController()
    // used to offset the overview webview content which is at the bottom
    // below the rest of the content
    private let topContentInsets = ConstantInsetsSource(insets: UIEdgeInsetsZero, affectsScrollIndicators: false)
    
    var action: ((completion : () -> Void) -> Void)?
    
    private var _loaded = Sink<()>()
    var loaded : Stream<()> {
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
        descriptionView.snp_makeConstraints {make in
            make.edges.equalTo(self)
        }
        container.snp_makeConstraints { make in
            make.top.equalTo(descriptionView)
            make.leading.equalTo(descriptionView)
            make.trailing.equalTo(descriptionView)
        }
        container.spacing = margin
        for stack in [container, fieldsList, insetContainer] {
            stack.axis = .Vertical
            stack.alignment = .Fill
        }
        
        insetContainer.layoutMarginsRelativeArrangement = true
        insetContainer.layoutMargins = UIEdgeInsetsMake(0, margin, 0, margin)
        insetContainer.spacing = margin
        
        insetsController.addSource(topContentInsets)
        
        fieldsList.layoutMarginsRelativeArrangement = true
        
        blurbLabel.numberOfLines = 0
        
        actionButton.oex_addAction({[weak self] _ in
            self?.actionButton.showProgress = true
            self?.action?( completion: { self?.actionButton.showProgress = false } )
            }, forEvents: .TouchUpInside)
        
        descriptionView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
        descriptionView.delegate = self
        descriptionView.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        
        playButton.setImage(Icon.CourseVideoPlay.imageWithFontSize(60), forState: .Normal)
        playButton.tintColor = OEXStyles.sharedStyles().neutralWhite()
        playButton.layer.shadowOpacity = 0.5
        playButton.layer.shadowRadius = 3
        playButton.layer.shadowOffset = CGSizeZero
        courseCard.addCenteredOverlay(playButton)

        descriptionView.scrollView.oex_addObserver(self, forKeyPath: "bounds") { (observer, scrollView, _) -> Void in
            let offset = scrollView.contentOffset.y + scrollView.contentInset.top
            // Even though it's in the webview's scrollview,
            // the container view doesn't offset when the content scrolls.
            // As such, we manually offset it here
            observer.container.transform = CGAffineTransformMakeTranslation(0, -offset)
        }
    }
    
    func setupInController(controller: UIViewController) {
        insetsController.setupInController(controller, scrollView: descriptionView.scrollView)
    }
    
    private var blurbStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralXDark())
    }
    
    private var descriptionHeaderStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Bold, size: .Large, color: OEXStyles.sharedStyles().neutralXDark())
    }
    
    private func fieldSeparator() -> UIView {
        let view = UIView()
        view.backgroundColor = OEXStyles.sharedStyles().neutralLight()
        view.snp_makeConstraints {make in
            make.height.equalTo(OEXStyles.dividerSize())
        }
        return view
    }
    
    var blurbText : String? {
        didSet {
            if let blurb = blurbText where !blurb.isEmpty {
                self.blurbLabel.attributedText = blurbStyle.attributedStringWithText(blurb)
                self.blurbLabel.hidden = false
            }
            else {
                self.blurbLabel.hidden = true
            }
        }
    }
    
    var descriptionHTML : String? {
        didSet {
            guard let html = OEXStyles.sharedStyles().styleHTMLContent(descriptionHTML, stylesheet: "inline-content") else {
                self.descriptionView.loadHTMLString("", baseURL: environment.networkManager.baseURL)
                return
            }
            
            self.descriptionView.loadHTMLString(html, baseURL: environment.networkManager.baseURL)
        }
    }
    
    private var fields : [Field] = [] {
        didSet {
            for view in self.fieldsList.arrangedSubviews {
                view.removeFromSuperview()
            }
            let views = fields.map{ viewForField($0) }.interpose { fieldSeparator() }
            
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
    
    func webViewDidFinishLoad(webView: UIWebView) {
        self.setNeedsLayout()
        self.layoutIfNeeded()
        webView.scrollView.contentOffset = CGPoint(x: 0, y: -webView.scrollView.contentInset.top)
        _loaded.send(())
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let URL = request.URL where navigationType != .Other {
            UIApplication.sharedApplication().openURL(URL)
            return false
        }
        return true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.topContentInsets.currentInsets = UIEdgeInsets(top: self.container.frame.height + StandardVerticalMargin, left: 0, bottom: 0, right: 0)
    }
    
    var actionText: String? {
        get {
            return self.actionButton.attributedTitleForState(.Normal)?.string
        }
        set {
            actionButton.applyButtonStyle(OEXStyles.sharedStyles().filledEmphasisButtonStyle, withTitle: newValue)
        }
    }
}

extension CourseCatalogDetailView {
    
    private func fieldsForCourse(course : OEXCourse) -> [Field] {
        var result : [Field] = []
        if let effort = course.effort where !effort.isEmpty {
            result.append(Field(name: Strings.CourseDetail.effort, value: effort, icon: .CourseEffort))
        }
        if let endDate = course.end where !course.isStartDateOld {
            let date = OEXDateFormatting.formatAsMonthDayYearString(endDate)
            result.append(Field(name: Strings.CourseDetail.endDate, value: date, icon: .CourseEnd))
        }
        return result
    }
    
    func applyCourse(course : OEXCourse) {
        CourseCardViewModel.onCourseCatalog(course).apply(courseCard, networkManager: self.environment.networkManager)
        self.blurbText = course.short_description
        self.descriptionHTML = course.overview_html
        let fields = fieldsForCourse(course)
        self.fields = fields
        self.playButton.hidden = course.courseVideoMediaInfo?.uri?.isEmpty ?? true
        self.playButton.oex_removeAllActions()
        self.playButton.oex_addAction(
            {[weak self] _ in
                if let
                    path = course.courseVideoMediaInfo?.uri,
                    url = NSURL(string: path, relativeToURL: self?.environment.networkManager.baseURL)
                {
                    UIApplication.sharedApplication().openURL(url)
                }
            }, forEvents: .TouchUpInside)
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
        return !self.playButton.hidden
    }
    
    var t_showingShortDescription : Bool {
        return !self.blurbLabel.hidden
    }
}

