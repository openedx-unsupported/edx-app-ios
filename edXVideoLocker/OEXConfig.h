//
//  OEXConfig.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/29/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXConfig : NSObject

- (id)initWithAppBundleData;

- (id)objectForKey:(NSString*)key;
- (NSString*)stringForKey:(NSString*)key;

@end


// Name all the known configuration keys
// So it's easy to find them all
// Use a full method instead of a constant name for the key
// in case we need to do something clever in individual cases
@interface OEXConfig (OEXKnownConfigs)

- (NSString*)environmentName;

// Network
- (NSString*)apiHostURL;
- (NSString*)courseSearchURL;
- (NSString*)feedbackEmailAddress;
- (NSString*)oauthClientID;
- (NSString*)oauthClientSecret;

// Third party keys
- (NSString*)segmentIOKey;
- (NSString*)fabricKey;
- (NSString*)facebookURLScheme;
- (NSString*)googlePlusKey;
- (NSString*)newRelicKey;

@end