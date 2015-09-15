//
//  Logger+OEXObjC.h
//  edX
//
//  Created by Akiva Leffert on 9/15/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "edX-Swift.h"

#define OEXLogDebug(domain, message) [Logger logError:domain :message file: @"" __FILE__ line:__LINE__]
#define OEXLogInfo(domain, message) [Logger logInfo:domain :message file: @"" __FILE__ line:__LINE__]
#define OEXLogError(domain, message) [Logger logError:domain :message file: @"" __FILE__ line:__LINE__]
