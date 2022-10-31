//
//  ExternalAuthOptionsView.swift
//  edX
//
//  Created by MuhammadUmer on 25/10/2022.
//  Copyright © 2022 edX. All rights reserved.
//

import UIKit

@objc enum ExternalAuthOptionsType: Int {
    case register
    case login
}

class ExternalAuthOptionsView: UIView {
    private let verticalOffset = 16
    private let buttonHeight = 44
    
    @objc var height: CGFloat {
        return CGFloat(providers.count * (verticalOffset + buttonHeight))
    }
    
    private let providers: [OEXExternalAuthProvider]
    private let type: ExternalAuthOptionsType
    private let accessibilityString: String
    private let tapAction: (OEXExternalAuthProvider) -> ()
    
    @objc init(frame: CGRect, providers: [OEXExternalAuthProvider], type: ExternalAuthOptionsType, accessibilityLabel: String, tapAction: @escaping (OEXExternalAuthProvider) -> ()) {
        self.providers = providers.sorted { $0.displayName < $1.displayName }
        self.type = type
        self.accessibilityString = accessibilityLabel
        self.tapAction = tapAction
        
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        configureAuthProviders()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureAuthProviders() {
        var container: UIView?
        for provider in providers {
            let button = UIButton()
            button.oex_addAction({ [weak self] _ in
                self?.tapAction(provider)
            }, for: .touchUpInside)
                        
            let title = type == .register ? Strings.continueWith(provider: provider.displayName) : Strings.signInWith(provider: provider.displayName)
            let authButtonContainer = provider.authView(withTitle: title)
            authButtonContainer.accessibilityIdentifier = "ExternalAuthOptionsView:\(provider.displayName.lowercased())-button"
            authButtonContainer.accessibilityLabel = "\(accessibilityString) \(title)"
            authButtonContainer.addSubview(button)
            addSubview(authButtonContainer)
            
            authButtonContainer.snp.makeConstraints { make in
                make.leading.equalTo(self)
                make.trailing.equalTo(self)
                if let container = container {
                    make.top.equalTo(container.snp.bottom).offset(verticalOffset)
                } else {
                    make.top.equalTo(self)
                }
                make.height.equalTo(buttonHeight)
            }
            
            button.snp.makeConstraints { make in
                make.edges.equalTo(authButtonContainer)
            }
            
            container = authButtonContainer
        }
    }
}
