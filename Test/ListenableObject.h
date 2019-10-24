//
//  ListenableObject.h
//  edX
//
//  Created by Saeed Bashir on 2/18/19.
//  Copyright © 2019 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ListenableObject: NSObject

@property (nonatomic) NSString *backing;
@property (nonatomic) NSString *value;

@end

NS_ASSUME_NONNULL_END
