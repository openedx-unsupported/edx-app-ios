//
//  VideoPlayerInterface.h
//  edX_videoStreaming
//
//  Created by Nirbhay Agarwal on 13/05/14.
//  Copyright (c) 2014 Clarice Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "CLVideoPlayer.h"
#import "HelperVideoDownload.h"
@protocol videoPlayerInterfaceDelegate <NSObject>

@optional
-(void)movieTimedOut;
-(void)playerWillStop:(CLVideoPlayer *)videoPlayer;

@end

@interface VideoPlayerInterface:UIViewController<CLVideoPlayerControllerDelegate>
@property(nonatomic,weak)id<videoPlayerInterfaceDelegate>  delegate;
@property (nonatomic, weak) UIView * videoPlayerVideoView;
@property (nonatomic, strong) CLVideoPlayer * moviePlayerController;
@property(nonatomic)BOOL shouldRotate;
-(void)orientationChanged:(NSNotification *)notification;
- (void)updatePlaybackRate:(float)newPlaybackRate;
//- (void)playVideoFromURL:(NSURL *)URL;
- (void)playVideoFor:(HelperVideoDownload *)video;
- (void)playVideoFromURL:(NSURL *)URL withTitle:(NSString *)title;
-(void)playVideoFromURL:(NSURL *)URL withTitle:(NSString *)title timeInterval:(NSTimeInterval)interval;
-(void)resetPlayer;
-(void)videoPlayerShouldRotate;
-(void)setAutoPlaying:(BOOL)playing;
@end
