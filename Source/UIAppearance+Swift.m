//
//  UIAppearance+Swift.m
//  edX
//
//  Created by Ehmad Zubair Chughtai on 08/10/2015.
//  Copyright © 2015 edX. All rights reserved.
//

#import "UIAppearance+Swift.h"

// UIAppearance+Swift.m
@implementation UIView (UIViewAppearance_Swift)
+ (instancetype)my_appearanceWhenContainedIn:(Class<UIAppearanceContainer>)containerClass {
    return [self appearanceWhenContainedIn:containerClass, nil];
}
@end