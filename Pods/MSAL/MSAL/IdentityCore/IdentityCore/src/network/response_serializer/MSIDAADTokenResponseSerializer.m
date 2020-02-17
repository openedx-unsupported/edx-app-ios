//
//  MSIDTokenResponseSerializer.m
//  IdentityCore
//
//  Created by Sergey Demchenko on 12/22/18.
//  Copyright © 2018 Microsoft. All rights reserved.
//

#import "MSIDAADTokenResponseSerializer.h"
#import "MSIDAADJsonResponsePreprocessor.h"

@implementation MSIDAADTokenResponseSerializer

- (instancetype)initWithOauth2Factory:(MSIDOauth2Factory *)oauth2Factory
{
    self = [super initWithOauth2Factory:oauth2Factory];
    if (self)
    {
        self.preprocessor = [MSIDAADJsonResponsePreprocessor new];
    }
    return self;
}

@end
