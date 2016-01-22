//
//  OEXURLSessionManager.h
//  edXVideoLocker
//
//  Created by Abhradeep on 12/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OEXURLSessionManager : NSObject

+ (instancetype)sharedURLSessionManager;

- (void)callAuthorizedWebServiceWithURLPath:(NSString*)urlPath method:(NSString*)method body:(NSData*)body completionHandler:(void (^)(NSData* data, NSURLResponse* response, NSError* error))completionHandle;

@end

NS_ASSUME_NONNULL_END
