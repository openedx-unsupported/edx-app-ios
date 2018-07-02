//
//  CropViewController.swift
//  edX
//
//  Created by Michael Katz on 10/19/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

private class CircleView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = OEXStyles.shared().neutralBlack().withAlphaComponent(0.8)
        isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var circleBounds: CGRect {
        let rect = bounds
        let minSize = min(rect.width, rect.height)
        let hole = CGRect(x: (rect.width - minSize) / 2, y: (rect.height - minSize) / 2, width: minSize, height: minSize).insetBy(dx: 6, dy: 6)
        return hole
    }
    
     override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        
        let hole = circleBounds
        context.addEllipse(in: hole);
        context.clip();
        context.clear(hole);
        context.setFillColor( UIColor.clear.cgColor);
        context.fill( hole);
        context.setStrokeColor(OEXStyles.shared().neutralLight().cgColor)
        context.strokeEllipse(in: hole)
        context.restoreGState()
    }
}

class CropViewController: UIViewController {
    
    var image: UIImage
    
    let imageView: UIImageView
    let scrollView: UIScrollView
    let titleLabel: UILabel
    let completion: (UIImage?) -> Void
    private let circleView: CircleView
    
    init(image: UIImage, completion: @escaping (UIImage?) -> Void) {
        self.image = image
        self.completion = completion
        imageView = UIImageView(image: image)
        scrollView = UIScrollView()
        circleView = CircleView()
        titleLabel = UILabel()
        
        super.init(nibName: nil, bundle: nil)
    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.addSubview(imageView)
        scrollView.contentSize = image.size
        scrollView.delegate = self
        
        view.addSubview(scrollView)
        view.backgroundColor = OEXStyles.shared().neutralBlack()
        
        let toolbar = buildToolbar()
        view.addSubview(circleView)
        view.addSubview(toolbar)
        
        let titleStyle = OEXStyles.shared().navigationTitleTextStyle
        titleLabel.attributedText = titleStyle.attributedString(withText: Strings.Profile.cropAndResizePicture)
        view.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(safeTop).offset(20)
            make.centerX.equalTo(view.snp.centerX)
        }
      
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
        
        toolbar.snp.makeConstraints { make in
            make.leading.equalTo(safeLeading)
            make.trailing.equalTo(safeTrailing)
            make.bottom.equalTo(safeBottom)
            make.height.equalTo(50)
        }
        
        circleView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView)
        }
        
        let tap = UITapGestureRecognizer()
        tap.addAction { [weak self]_ in
            self?.zoomOut()
        }
        tap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(tap)

    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
  
    private func buildToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.barTintColor = UIColor.clear
        toolbar.tintColor = OEXStyles.shared().neutralWhiteT()
       
        let cancelButton = UIButton(type:.system)
        cancelButton.frame = CGRect(x: 0,y: 0, width: 100, height: 44)
        cancelButton.setTitle(Strings.cancel, for: .normal)
        cancelButton.setTitleColor(OEXStyles.shared().neutralWhiteT(), for: .normal)
        cancelButton.sizeToFit()

        let cancel = UIBarButtonItem(customView: cancelButton)
        cancelButton.oex_addAction({ [weak self] _ in
            self?.completion(nil)
            }, for: .touchUpInside)

        let chooseButton = UIButton(type:.system)
        chooseButton.frame = CGRect(x: 0,y: 0, width: 100, height: 44)
        chooseButton.setTitle(Strings.choose, for: .normal)
        chooseButton.setTitleColor(OEXStyles.shared().neutralWhiteT(), for: .normal)
        chooseButton.sizeToFit()

        let choose = UIBarButtonItem(customView: chooseButton)
        chooseButton.oex_addAction({ [weak self] _ in
            let rect = self!.circleView.circleBounds
            let shift = rect.applying(CGAffineTransform(translationX: self!.scrollView.contentOffset.x, y: self!.scrollView.contentOffset.y))
            let scaled = shift.applying(CGAffineTransform(scaleX: 1.0 / self!.scrollView.zoomScale, y: 1.0 / self!.scrollView.zoomScale))
            let newImage = self?.image.imageCropped(toRect: scaled)
            self?.completion(newImage)
            }, for: .touchUpInside)
        
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        var items = [cancel, flex, choose]
        if toolbar.isRightToLeft {
            items = items.reversed()
        }
        toolbar.items = items
        
        return toolbar
    }
  
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        OEXAnalytics.shared().trackScreen(withName: OEXAnalyticsScreenCropPhoto)

        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let scrollFrame = scrollView.frame
        let hole = circleView.circleBounds
        
        let imSize = image.size
        guard hole.width > 0 else { return }
        
        let verticalRatio = hole.height / imSize.height
        let horizontalRatio = hole.width / imSize.width
        
        scrollView.minimumZoomScale = max(horizontalRatio, verticalRatio)
        scrollView.maximumZoomScale = 1
        scrollView.zoomScale = scrollView.minimumZoomScale
        
        let insetHeight = (scrollFrame.height - hole.height) / 2
        let insetWidth = (scrollFrame.width - hole.width) / 2
        scrollView.contentInset = UIEdgeInsetsMake(insetHeight, insetWidth, insetHeight, insetWidth)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension CropViewController: UIScrollViewDelegate {
    func zoomOut() {
        let newScale = scrollView.zoomScale == scrollView.minimumZoomScale ? 0.5 : scrollView.minimumZoomScale
        scrollView.setZoomScale(newScale, animated: true)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        //need empty implementation for zooming
    }
}
