//
//  ExternalAuthOptionsView.swift
//  edX
//
//  Created by MuhammadUmer on 25/10/2022.
//  Copyright © 2022 edX. All rights reserved.
//

import UIKit

@objc enum ExternalAuthOptionsViewState: Int {
    case register
    case login
}

class ExternalAuthOptionsView: UIView {
    
    private let offset = 16
    private let buttonHeight = 44
    
    @objc var height: CGFloat {
        return CGFloat(providers.count * (offset + buttonHeight))
    }
    
    private let providers: [OEXExternalAuthProvider]
    private let state: ExternalAuthOptionsViewState
    private let accessibilityString: String
    private let tapAction: (OEXExternalAuthProvider) -> ()
    
    @objc init(frame: CGRect, providers: [OEXExternalAuthProvider], state: ExternalAuthOptionsViewState, accessibilityLabel: String, tapAction: @escaping (OEXExternalAuthProvider) -> ()) {
        self.providers = providers.sorted { $0.displayName < $1.displayName }
        self.state = state
        self.accessibilityString = accessibilityLabel
        self.tapAction = tapAction
        
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        addSubViews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubViews() {
        var container: UIView?
        for provider in providers {
            let button = UIButton()
            button.oex_addAction({ [weak self] _ in
                self?.tapAction(provider)
            }, for: .touchUpInside)
                        
            let text = state == .register ? Strings.signInWith(provider: provider.displayName) : Strings.continueWith(provider: provider.displayName)
            let authButtonContainer = provider.makeAuthView(text)
            authButtonContainer.accessibilityIdentifier = "ExternalAuthOptionsView:\(provider.displayName.lowercased())-button"
            authButtonContainer.accessibilityLabel = "\(accessibilityString) \(text)"
            authButtonContainer.addSubview(button)
            addSubview(authButtonContainer)
            
            authButtonContainer.snp.makeConstraints { make in
                make.leading.equalTo(self)
                make.trailing.equalTo(self)
                if let container = container {
                    make.top.equalTo(container.snp.bottom).offset(offset)
                } else {
                    make.top.equalTo(self)
                }
                make.height.equalTo(44)
            }
            
            button.snp.makeConstraints { make in
                make.edges.equalTo(authButtonContainer)
            }
            
            container = authButtonContainer
        }
    }
}
