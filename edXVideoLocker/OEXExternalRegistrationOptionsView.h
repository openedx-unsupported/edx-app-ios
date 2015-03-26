//
//  OEXExternalRegistrationOptionsView.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXExternalRegistrationOptionsView;
@protocol OEXExternalAuthProvider;

@protocol OEXExternalRegistrationOptionsViewDelegate <NSObject>

- (void)optionsView:(OEXExternalRegistrationOptionsView*)view choseProvider:(id <OEXExternalAuthProvider>)provider;

@end

@interface OEXExternalRegistrationOptionsView : UIView

- (id)initWithFrame:(CGRect)frame providers:(NSArray*)providers NS_DESIGNATED_INITIALIZER;

@property (weak, nonatomic) id <OEXExternalRegistrationOptionsViewDelegate> delegate;
@property (readonly, nonatomic) CGFloat desiredHeight;

@end
