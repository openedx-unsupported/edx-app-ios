//
//  OEXURLSessionManager.h
//  edXVideoLocker
//
//  Created by Abhradeep on 12/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXURLSessionManager : NSObject

+ (instancetype)sharedURLSessionManager;

- (void)callAuthorizedWebServiceWithURLPath:(NSString*)urlPath method:(NSString*)method body:(NSData*)body completionHandler:(void (^)(NSData* data, NSURLResponse* response, NSError* error))completionHandle;

@end
