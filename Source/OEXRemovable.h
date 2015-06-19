//
//  OEXRemovable.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

// This protocol should be avoided in Swift code. See plain "Removable"
@protocol OEXRemovable <NSObject>

- (void)remove;

@end