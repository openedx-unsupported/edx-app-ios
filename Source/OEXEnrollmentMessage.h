//
//  OEXEnrollmentMessage.h
//  edXVideoLocker
//
//  Created by Abhradeep on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OEXEnrollmentMessage : NSObject

- (id)initWithMessage:(NSString *)message shouldReloadTable:(BOOL)shouldReload;

@property (strong, nonatomic) NSString* messageBody;
@property (nonatomic) BOOL shouldReloadTable;

@end

NS_ASSUME_NONNULL_END
