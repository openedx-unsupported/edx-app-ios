//
//  NSError+OEXKnownErrors.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/19/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (OEXKnownErrors)

- (BOOL)oex_isNoInternetConnectionError;

@end
