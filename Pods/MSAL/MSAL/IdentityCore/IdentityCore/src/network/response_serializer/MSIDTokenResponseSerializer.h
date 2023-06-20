//
//  MSIDTokenResponseSerializer.h
//  IdentityCore
//
//  Created by Sergey Demchenko on 12/24/18.
//  Copyright © 2018 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSIDHttpResponseSerializer.h"

@class MSIDOauth2Factory;

NS_ASSUME_NONNULL_BEGIN

@interface MSIDTokenResponseSerializer : MSIDHttpResponseSerializer

- (instancetype _Nullable)initWithOauth2Factory:(nonnull MSIDOauth2Factory *)oauth2Factory NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, readonly) MSIDOauth2Factory *oauth2Factory;

@end

NS_ASSUME_NONNULL_END
