//
//  OEXExternalRegistrationOptionsView.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class OEXExternalRegistrationOptionsView;
@protocol OEXExternalAuthProvider;

@protocol OEXExternalRegistrationOptionsViewDelegate <NSObject>

- (void)optionsView:(OEXExternalRegistrationOptionsView*)view choseProvider:(id <OEXExternalAuthProvider>)provider;

@end

@interface OEXExternalRegistrationOptionsView : UIView

- (id)initWithFrame:(CGRect)frame providers:(NSArray*)providers;

@property (weak, nonatomic, nullable) id <OEXExternalRegistrationOptionsViewDelegate> delegate;

- (void)beginIndicatingActivity;
- (void)endIndicatingActivity;
- (CGFloat)heightForAuthView;

@end

NS_ASSUME_NONNULL_END
