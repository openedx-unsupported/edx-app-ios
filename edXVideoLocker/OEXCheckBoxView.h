//
//  OEXCheckBoxView.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OEXCheckBoxView : UIView
-(void)setLabelText:(NSString *)title;
-(void)setSelected:(BOOL)selected;
-(BOOL)isSelected;
@end
