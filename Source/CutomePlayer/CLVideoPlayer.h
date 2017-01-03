//
//  CLVideoPlayer.h
//  CLMoviePlayer
//
//  Created by Jotiram Bhagat on 24/06/14.
//  Copyright (c) 2014-2016 Jotiram Bhagat. All rights reserved.
//

@import MediaPlayer;
#import "CLVideoPlayerControls.h"

NS_ASSUME_NONNULL_BEGIN

static NSString* const CLVideoPlayerContentURLDidChangeNotification = @"CLVideoPlayerContentURLDidChangeNotification";

@protocol CLVideoPlayerControllerDelegate <NSObject>
@optional
- (void)movieTimedOut;
- (void)playerDidStopPlaying:(NSURL*)nsurl atPlayBackTime:(float)timeinterval;
- (void)videoPlayerTapped:(id) sender;
- (void)transcriptLoaded:(NSArray *)transcript;
@required
- (void)moviePlayerWillMoveFromWindow;
@end

@interface CLVideoPlayer : MPMoviePlayerController<CLVideoPlayerControlsDelegate> {
}

- (void)setFullscreen:(BOOL)fullscreen animated:(BOOL)animated forceRotate:(BOOL)rotate;
- (void)setFrame:(CGRect)frame;
- (id)initWithFrame:(CGRect)frame;
- (void)setFullscreen:(BOOL)fullscreen withOrientation:(UIInterfaceOrientation)orientation;
- (void)setFullscreen:(BOOL)fullscreen withOrientation:(UIInterfaceOrientation) orientation animated:(BOOL)animated forceRotate:(BOOL)rotate;
- (void)resetMoviePlayer;

@property (nonatomic, weak, nullable) id <CLVideoPlayerControllerDelegate> delegate;
@property (nonatomic, strong, nullable) CLVideoPlayerControls* controls;
@property(nonatomic, strong) NSString* videoTitle;
@property(nonatomic) float lastPlayedTime;
@property(nonatomic) float startTime;
@property(nonatomic, assign) BOOL autoPlaying;

@end

NS_ASSUME_NONNULL_END
