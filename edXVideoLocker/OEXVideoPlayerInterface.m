//
//  OEXVideoPlayerInterface.m
//  edX_videoStreaming
//
//  Created by Nirbhay Agarwal on 13/05/14.
//  Copyright (c) 2014 edX, Inc. All rights reserved.
//

#import "OEXVideoPlayerInterface.h"
#import "OEXInterface.h"
#import "OEXHelperVideoDownload.h"
#import "OEXVideoSummary.h"

@interface OEXVideoPlayerInterface ()
{
    UILabel *labelTitle;
    
}

@property(nonatomic,assign)CGRect defaultFrame;
@property(nonatomic)CGFloat lastPlayedTime;
@property(nonatomic,strong)OEXHelperVideoDownload *currentVideo;
@property(nonatomic,strong)OEXHelperVideoDownload *lastPlayedVideo;
@property(nonatomic,strong)NSURL *currentUrl;

@end

@implementation OEXVideoPlayerInterface



- (void)viewDidLoad
{
    [super viewDidLoad];
}


-(void)resetPlayer{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self.moviePlayerController.controls];
    [[NSNotificationCenter defaultCenter] removeObserver:self.moviePlayerController];
    [self.moviePlayerController setContentURL:nil];
    self.moviePlayerController.delegate=nil;
    [self.moviePlayerController resetMoviePlayer];
    self.moviePlayerController.controls=nil;
    self.moviePlayerController=nil;
    self.delegate=nil;
    
}

- (id)init {
    
    self = [super init];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    //Add observer
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exitFullScreenMode:) name:MPMoviePlayerDidExitFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterFullScreenMode:) name:MPMoviePlayerDidEnterFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStateChanged:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification object:_moviePlayerController];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackEnded:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification object:_moviePlayerController];
    
    
    
    //create a player
    self.moviePlayerController = [[CLVideoPlayer alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.moviePlayerController.view.alpha = 0.f;
    self.moviePlayerController.delegate = self; //IMPORTANT!
    
    //create the controls
    CLVideoPlayerControls *movieControls = [[CLVideoPlayerControls alloc] initWithMoviePlayer:self.moviePlayerController style:CLVideoPlayerControlsStyleDefault];
    [movieControls setBarColor:[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.9]];
    [movieControls setTimeRemainingDecrements:YES];
    //assign controls
    [self.moviePlayerController setControls:movieControls];
    _shouldRotate=YES;
    return self;
    
}

- (void)playVideoFromURL:(NSURL *)URL withTitle:(NSString *)title{
    _moviePlayerController.videoTitle=title;
    [self playVideoFromURL:URL withTitle:title timeInterval:0];
}


- (void)playVideoFor:(OEXHelperVideoDownload *)video
{
    _moviePlayerController.videoTitle = video.summary.name;
    NSURL *url = [NSURL URLWithString:video.summary.videoURL];
    
    NSFileManager *filemgr = [NSFileManager defaultManager];
    NSString *slink = [video.filePath stringByAppendingPathExtension:@"mp4"];
    
    if ([filemgr fileExistsAtPath:slink]) {
        url=[NSURL fileURLWithPath:slink];
    }
    
    if(video.state==OEXDownloadStateComplete && ![filemgr fileExistsAtPath:slink]){
        return;
    }
    
    float timeinterval=[[OEXInterface sharedInterface] lastPlayedIntervalForVideo:video];
    [self updateLastPlayedVideoWith:video];
    [self playVideoFromURL:url withTitle:video.summary.name timeInterval:timeinterval];
}


-(void)setVideoPlayerVideoView:(UIView *)videoPlayerVideoView{
    
    _videoPlayerVideoView=videoPlayerVideoView;
    self.view=_videoPlayerVideoView;
    
}

-(void)playVideoFromURL:(NSURL *)URL withTitle:(NSString *)title timeInterval:(NSTimeInterval)interval;
{
    if(!URL)
        return;
    self.view=_videoPlayerVideoView;
    _moviePlayerController.videoTitle=title;
    self.lastPlayedTime=interval;
    [_moviePlayerController.view setBackgroundColor:[UIColor blackColor]];
    // [_moviePlayerController setContentURL:nil];
    //[_moviePlayerController stop];
    [_moviePlayerController setContentURL:URL];
    [_moviePlayerController prepareToPlay];
    [_moviePlayerController setAutoPlaying:YES];
    _moviePlayerController.lastPlayedTime=interval;
    //[_moviePlayerController setInitialPlaybackTime:interval];
    [_moviePlayerController play];
    _moviePlayerController.controls.playbackRate=1.0;   // We do not persist speed so set default for new video
    [_moviePlayerController setCurrentPlaybackRate:1.0];
    if(!_moviePlayerController.isFullscreen )
    {
        [_moviePlayerController.view setFrame:_videoPlayerVideoView.bounds];
        [self.view addSubview:_moviePlayerController.view];
    }
    
    self.moviePlayerController.view.alpha=0.0f;
    double delayInSeconds = 0.3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [self configureViewForOrientation:[UIApplication sharedApplication].statusBarOrientation];
        [UIView animateWithDuration:1.0 animations:^{
            self.moviePlayerController.view.alpha = 1.f;
        }];
    });
    
}


-(void)setAutoPlaying:(BOOL)playing{

    [self.moviePlayerController setAutoPlaying:playing];
    self.moviePlayerController.shouldAutoplay=playing;
    
}

-(void)updateLastPlayedVideoWith:(OEXHelperVideoDownload *)video{
    if(_currentVideo){
        _lastPlayedVideo=_currentVideo;
    }else{
        _lastPlayedVideo=video;
    }
    _currentVideo=video;
}


#pragma mark video player delegate

-(void)movieTimedOut{
    
    if([self.delegate respondsToSelector:@selector(movieTimedOut)]){
        [self.delegate performSelector:@selector(movieTimedOut)];
    }
    
}


#pragma mark notification methods


- (void)playbackStateChanged:(NSNotification *)notification
{
    
    switch ([_moviePlayerController playbackState])
    {
        case MPMoviePlaybackStateStopped:
            //NSLog(@"Stopped");
            break;
        case MPMoviePlaybackStatePlaying:
            
            break;
        case MPMoviePlaybackStatePaused:
            //NSLog(@"Paused");
            break;
        case MPMoviePlaybackStateInterrupted:
            //NSLog(@"Interrupted");
            break;
        case MPMoviePlaybackStateSeekingForward:
            //NSLog(@"Seeking Forward");
            break;
        case MPMoviePlaybackStateSeekingBackward:
            //NSLog(@"Seeking Backward");
            break;
        default:
            break;
            
    }
    
}


- (void)playbackEnded:(NSNotification *)notification {
    
    int reason = [[[notification userInfo] valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    if (reason == MPMovieFinishReasonPlaybackEnded) {
        //NSLog(@"Reason: movie finished playing");
        
    }else if (reason == MPMovieFinishReasonUserExited) {
        //NSLog(@"Reason: user hit done button");
        
    }else if (reason == MPMovieFinishReasonPlaybackError) {
        //NSLog(@"Reason: error --> VideoPlayerInterface.m");
        [self.moviePlayerController.view removeFromSuperview];
    }
    
    
}


-(void)viewWillDisappear:(BOOL)animated{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [_moviePlayerController setShouldAutoplay:NO];
    _shouldRotate=NO;
    
}

-(void)viewWillAppear:(BOOL)animated{
     [_moviePlayerController setShouldAutoplay:YES];
    _shouldRotate=YES;
}


-(void)videoPlayerShouldRotate
{
    [_moviePlayerController setShouldAutoplay:YES];
    _shouldRotate=YES;
}

-(void)orientationChanged:(NSNotification *)notification{
    if(_shouldRotate){
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(manageOrientation) object:nil];
        UIDeviceOrientation deviceorientation = [[UIDevice currentDevice] orientation];
        if(deviceorientation==UIDeviceOrientationFaceUp || deviceorientation==UIDeviceOrientationFaceDown){
            [self manageOrientation];
        }else{
            [self performSelector:@selector(manageOrientation) withObject:nil afterDelay:0.8];
        }
    }
}


-(void)manageOrientation
{
    
    if(!((self.moviePlayerController.playbackState == MPMoviePlaybackStatePlaying) || self.moviePlayerController.playbackState == MPMoviePlaybackStatePaused )  &&  !_moviePlayerController.isFullscreen)
        return;
    
    UIDeviceOrientation deviceorientation = [[UIDevice currentDevice] orientation];
    
    if(((deviceorientation==UIDeviceOrientationFaceDown) || (deviceorientation==UIDeviceOrientationFaceUp))){
        return;
    }
    
    if (deviceorientation == UIInterfaceOrientationPortrait || deviceorientation == UIInterfaceOrientationPortraitUpsideDown ||
        (deviceorientation==UIDeviceOrientationFaceDown)||
        (deviceorientation==UIDeviceOrientationFaceUp))// PORTRAIT MODE
    {
        if(self.moviePlayerController.fullscreen){
            [_moviePlayerController setFullscreen:NO withOrientation:UIDeviceOrientationPortrait];
            [_moviePlayerController.controls setStyle:CLVideoPlayerControlsStyleEmbedded];
        }
        
    }   //LANDSCAPE MODE
    else if (deviceorientation == UIDeviceOrientationLandscapeLeft || deviceorientation == UIDeviceOrientationLandscapeRight)
    {
        [_moviePlayerController setFullscreen:YES withOrientation:deviceorientation];
        [_moviePlayerController.controls setStyle:CLVideoPlayerControlsStyleFullscreen];
    }
    
    //
    //   if(((deviceorientation==UIDeviceOrientationFaceDown) || (deviceorientation==UIDeviceOrientationFaceUp))){
    //       if(!self.moviePlayerController.isFullscreen){
    //           return;
    //       }
    //       else{
    //           [self.moviePlayerController setFullscreen:NO];
    //       }
    //    }
    //
    //    if (deviceorientation == UIInterfaceOrientationPortrait || deviceorientation == UIInterfaceOrientationPortraitUpsideDown ||
    //        (deviceorientation==UIDeviceOrientationFaceDown)||
    //        (deviceorientation==UIDeviceOrientationFaceUp))// PORTRAIT MODE
    //    {
    //        if(self.moviePlayerController.fullscreen)
    //        [_moviePlayerController setFullscreen:NO];
    //        [_moviePlayerController.controls setStyle:CLVideoPlayerControlsStyleEmbedded];
    //    }   //LANDSCAPE MODE
    //    else if (deviceorientation == UIDeviceOrientationLandscapeLeft || deviceorientation == UIDeviceOrientationLandscapeRight)
    //    {
    //        [_moviePlayerController setFullscreen:YES];
    //        [_moviePlayerController.controls setStyle:CLVideoPlayerControlsStyleFullscreen];
    //    }else{
    //
    //    }
    
}


-(void)exitFullScreenMode:(NSNotification *)notification{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}


-(void)enterFullScreenMode:(NSNotification *)notification{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}


- (void)configureViewForOrientation:(UIInterfaceOrientation)orientation {
    
    CGFloat videoWidth = 0;
    CGFloat videoHeight = 0;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        videoWidth = 700.f;
        videoHeight = 535.f;
    } else {
        videoWidth = self.view.frame.size.width;
        videoHeight = 220.f;
    }
    //calulate the frame on every rotation, so when we're returning from fullscreen mode we'll know where to position the movie plauyer
    self.defaultFrame = CGRectMake(self.view.frame.size.width/2 - videoWidth/2, self.view.frame.size.height/2 - videoHeight/2, videoWidth, videoHeight);
    
    //only manage the movie player frame when it's not in fullscreen. when in fullscreen, the frame is automatically managed
    
    
    if (self.moviePlayerController.isFullscreen)
        return;
    
    //you MUST use [CLMoviePlayerController setFrame:] to adjust frame, NOT [CLMoviePlayerController.view setFrame:]
    [self.moviePlayerController setFrame:self.defaultFrame];
    //    self.moviePlayerController.view.layer.borderColor = [UIColor redColor].CGColor;
    //    self.moviePlayerController.view.layer.borderWidth = 2;
}


-(void)moviePlayerWillMoveFromWindow{
    
    //movie player must be readded to this view upon exiting fullscreen mode.
    
    
    if (![self.view.subviews containsObject:self.moviePlayerController.view])
        [self.view addSubview:self.moviePlayerController.view];
    
    //you MUST use [CLMoviePlayerController setFrame:] to adjust frame, NOT [CLMoviePlayerController.view setFrame:]
    //NSLog(@"set frame from  player delegate ");
    [self.moviePlayerController setFrame:self.defaultFrame];
}

-(void)playerDidStopPlaying:(NSURL *)videoUrl atPlayBackTime:(float)timeinterval{
    
    NSString *url=[videoUrl absoluteString];
    
    if([_lastPlayedVideo.summary.videoURL isEqualToString:url] || [_lastPlayedVideo.filePath isEqualToString:url]){
        if(timeinterval > 0 ){
            [[OEXInterface sharedInterface] markLastPlayedInterval:timeinterval forVideo:_lastPlayedVideo];
        }
    }else{
        if(timeinterval > 0 ){
            [[OEXInterface sharedInterface] markLastPlayedInterval:timeinterval forVideo:_currentVideo];
        }
    }
    
}


-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
}

///Video interface
- (void)updatePlaybackRate:(float)newPlaybackRate
{
    [_moviePlayerController pause];
    [_moviePlayerController setCurrentPlaybackRate:newPlaybackRate];
    [_moviePlayerController prepareToPlay];
    [_moviePlayerController play];
}


- (void)didReceiveMemoryWarning
{
    ELog(@"MemoryWarning StatusMessageViewController");
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerDidExitFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerDidEnterFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackStateDidChangeNotification object:_moviePlayerController];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification object:_moviePlayerController];
    
      self.delegate=nil;
    _moviePlayerController.delegate=nil;
    _moviePlayerController=nil;
    _videoPlayerVideoView=nil;
    
    ELog(@"Dealloc get called VideoPlayerInterface");
    
    
}


@end
