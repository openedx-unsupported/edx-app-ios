//
//  RouterEnvironment.swift
//  edX
//
//  Created by Akiva Leffert on 11/30/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

@objc public class RouterEnvironment: NSObject, OEXAnalyticsProvider, OEXConfigProvider, DataManagerProvider, OEXInterfaceProvider, NetworkManagerProvider, ReachabilityProvider, OEXRouterProvider, OEXSessionProvider, OEXStylesProvider {
    public let analytics: OEXAnalytics
    public let config: OEXConfig
    public let dataManager: DataManager
    public let reachability: Reachability
    public let interface: OEXInterface?
    public let networkManager: NetworkManager
    weak public var router: OEXRouter?
    public let session: OEXSession
    public let styles: OEXStyles
    
    @objc init(
        analytics: OEXAnalytics,
        config: OEXConfig,
        dataManager: DataManager,
        interface: OEXInterface?,
        networkManager: NetworkManager,
        reachability: Reachability,
        session: OEXSession,
        styles: OEXStyles
        )
    {
        self.analytics = analytics
        self.config = config
        self.dataManager = dataManager
        self.interface = interface
        self.networkManager = networkManager
        self.reachability = reachability
        self.session = session
        self.styles = styles
        super.init()
    }
}
