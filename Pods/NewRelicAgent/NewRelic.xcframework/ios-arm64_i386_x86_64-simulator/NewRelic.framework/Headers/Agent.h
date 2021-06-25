//
//  Agent.h
//  Agent
//
//  Created by Bryce Buchanan on 7/23/20.
//  Copyright © 2020 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for Agent.
FOUNDATION_EXPORT double AgentVersionNumber;

//! Project version string for Agent.
FOUNDATION_EXPORT const unsigned char AgentVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Agent/PublicHeader.h>

#import "NewRelic.h"
#import "NRConstants.h"
#import "NewRelicCustomInteractionInterface.h"
#import "NewRelicFeatureFlags.h"
#import "NRCustomMetrics.h"
#import "NRLogger.h"
#import "NRCustomMetrics.h"
#import "NRTimer.h"
#import "NRURLSessionTaskDelegateBase.h"
#import "NRWKNavigationDelegateBase.h"
