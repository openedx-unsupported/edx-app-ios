//
//  OEXCast.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/27/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>


#define OEXSafeCastAsClass(obj, klass) ([obj isKindOfClass:[klass class]] ? (klass*)obj : nil)
#define OEXSafeCastAsProtocol(obj, pcol) ([obj conformsToProtocol:@protocol(pcol)] ? (id <pcol>)obj : nil)
