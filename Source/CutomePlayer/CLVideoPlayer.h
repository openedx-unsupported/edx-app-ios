//
//  CLVideoPlayer.h
//  CLMoviePlayer
//
//  Created by Jotiram Bhagat on 24/06/14.
//  Copyright (c) 2014 Jotiram Bhagat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "CLVideoPlayerControls.h"

static NSString* const CLVideoPlayerContentURLDidChangeNotification = @"CLVideoPlayerContentURLDidChangeNotification";

@protocol CLVideoPlayerControllerDelegate <NSObject>
@optional
- (void)movieTimedOut;
- (void)playerDidStopPlaying:(NSURL*)nsurl atPlayBackTime:(float)timeinterval;
@required
- (void)moviePlayerWillMoveFromWindow;
@end

@interface CLVideoPlayer : MPMoviePlayerController {
}

- (void)setFullscreen:(BOOL)fullscreen animated:(BOOL)animated forceRotate:(BOOL)rotate;
- (void)setFrame:(CGRect)frame;
- (id)initWithFrame:(CGRect)frame;
- (void)setFullscreen:(BOOL)fullscreen withOrientation:(UIDeviceOrientation)orientation;
- (void)resetMoviePlayer;

@property (nonatomic, weak) id <CLVideoPlayerControllerDelegate> delegate;
@property (nonatomic, strong) CLVideoPlayerControls* controls;
@property(nonatomic, strong) NSString* videoTitle;
@property(nonatomic) float lastPlayedTime;
@property(nonatomic) float startTime;
@property(nonatomic, assign) BOOL autoPlaying;

@end
