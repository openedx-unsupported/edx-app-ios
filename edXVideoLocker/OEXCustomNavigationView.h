//
//  OEXCustomNavigationView.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 13/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OEXCustomNavigationView : UIView

- (void)adjustPositionOfComponentsWithEditingMode:(BOOL)isEditingMode isOnline:(BOOL)online;
- (void)adjustPositionIfOnline:(BOOL)online;


@property (nonatomic , assign) BOOL isShifted;
@property (strong, nonatomic) UIButton *btn_Back;
@property (strong, nonatomic) UILabel *lbl_TitleView;
@property (strong, nonatomic) UILabel *lbl_Offline;
@property (strong, nonatomic) UIImageView *imgSeparator;
@property (strong, nonatomic) UIView *view_Offline;
@end
