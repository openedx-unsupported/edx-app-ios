//
//  OEXVideoPlayerInterface.h
//  edX_videoStreaming
//
//  Created by Nirbhay Agarwal on 13/05/14.
//  Copyright (c) 2014 edX, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "CLVideoPlayer.h"
#import "OEXHelperVideoDownload.h"

@protocol OEXVideoPlayerInterfaceDelegate <NSObject>

@optional
-(void)movieTimedOut;
-(void)playerWillStop:(CLVideoPlayer*)videoPlayer;

@end

@interface OEXVideoPlayerInterface : UIViewController <CLVideoPlayerControllerDelegate>

@property(nonatomic, weak) id <OEXVideoPlayerInterfaceDelegate>  delegate;
@property (nonatomic, weak) UIView* videoPlayerVideoView;
@property (nonatomic, strong) CLVideoPlayer* moviePlayerController;
@property(nonatomic) BOOL shouldRotate;

-(void)orientationChanged:(NSNotification*)notification;
- (void)updatePlaybackRate:(float)newPlaybackRate;
//- (void)playVideoFromURL:(NSURL *)URL;
- (void)playVideoFor:(OEXHelperVideoDownload*)video;
-(void)resetPlayer;
-(void)videoPlayerShouldRotate;
-(void)setAutoPlaying:(BOOL)playing;

@end
