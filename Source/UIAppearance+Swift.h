//
//  UIAppearance+Swift.h
//  edX
//
//  Created by Ehmad Zubair Chughtai on 08/10/2015.
//  Copyright © 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

//Make sure we remove this when we drop iOS8 support

@interface UIView (UIViewAppearance_Swift)
// appearanceWhenContainedIn: is not available in Swift. This fixes that.
+ (instancetype)my_appearanceWhenContainedIn:(Class<UIAppearanceContainer>)containerClass;
@end
