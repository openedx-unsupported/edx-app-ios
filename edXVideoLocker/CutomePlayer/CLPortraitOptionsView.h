//
//  CLPortraitOptionsView.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 21/08/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CLPortraitOptionsView : UIViewController

- (IBAction)cancelBtnClicked:(id)sender;
- (void)addViewToContainerSuperview:(UIView *)parentView;
- (void)removeSelfFromSuperView;
- (void)addValueToArray:(NSDictionary *)dictValues;


+ (id)sharedInstance;

@property (weak, nonatomic) IBOutlet UIView *view_Inner;


@property (weak, nonatomic) IBOutlet UITableView *table_Values;
@property (weak, nonatomic) IBOutlet UIButton *btn_Cancel;
@property (nonatomic, strong) NSMutableArray *arr_Values;

@end
