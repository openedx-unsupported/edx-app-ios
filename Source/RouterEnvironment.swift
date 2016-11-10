//
//  RouterEnvironment.swift
//  edX
//
//  Created by Akiva Leffert on 11/30/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

@objc class RouterEnvironment: NSObject, OEXAnalyticsProvider, OEXConfigProvider, DataManagerProvider, OEXInterfaceProvider, NetworkManagerProvider, ReachabilityProvider, OEXRouterProvider, OEXSessionProvider, OEXStylesProvider {
    let analytics: OEXAnalytics
    let config: OEXConfig
    let dataManager: DataManager
    let reachability: Reachability
    let interface: OEXInterface?
    let networkManager: NetworkManager
    weak var router: OEXRouter?
    let session: OEXSession
    let styles: OEXStyles
    
    init(
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
