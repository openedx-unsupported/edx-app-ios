//
//  OEXCheckBoxView.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

IB_DESIGNABLE
@interface OEXCheckBoxView : UIView
- (void)setLabelText:(NSString*)title IBInspectable;

@property (nonatomic) BOOL selected IBInspectable;
@end

NS_ASSUME_NONNULL_END
