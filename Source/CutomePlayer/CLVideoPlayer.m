//
//  CLVideoPlayer.m
//  CLMoviePlayer
//
//  Created by Jotiram Bhagat on 24/06/14.
//  Copyright (c) 2014 Jotiram Bhagat. All rights reserved.
//

#import "CLVideoPlayer.h"

@implementation UIDevice (ALSystemVersion)

+ (float)iOSVersion {
    static float version = 0.f;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        version = [[[UIDevice currentDevice] systemVersion] floatValue];
    });
    return version;
}

@end

@implementation UIApplication (ALAppDimensions)

+ (CGSize)sizeInOrientation:(UIInterfaceOrientation)orientation {
    CGSize size = [UIScreen mainScreen].bounds.size;
    if(UIInterfaceOrientationIsLandscape(orientation)) {
        size = CGSizeMake(size.height, size.width);
    }
    return size;
}

@end

static const CGFloat movieBackgroundPadding = 0.f;      //if we don't pad the movie's background view, the edges will appear jagged when rotating
static const NSTimeInterval fullscreenAnimationDuration = 0.3;

@interface CLVideoPlayer ()

@property (nonatomic, strong) UIView* movieBackgroundView;
@property (nonatomic, readwrite) BOOL movieFullscreen;
@property(nonatomic, strong) NSURL* currentContentUrl;
@end

@implementation CLVideoPlayer

# pragma mark - Construct/Destruct

- (id)init {
    return [self initWithFrame:CGRectZero];
}

- (id)initWithContentURL:(NSURL*)url {
    [[NSException exceptionWithName:@"CLMoviePlayerController Exception" reason:@"Set contentURL after initialization." userInfo:nil] raise];
    return nil;
}

- (id)initWithFrame:(CGRect)frame {
    // To resolve iOS 8 player crash.
#ifdef __IPHONE_8_0
    if(IS_IOS8) {
        self = [super initWithContentURL:nil];
    }
    else
#endif
    self = [super init];

    if(self) {
        self.view.frame = frame;
        self.view.backgroundColor = [UIColor blackColor];
        [self setControlStyle:MPMovieControlStyleNone];

        _movieFullscreen = NO;

        if(!_movieBackgroundView) {
            _movieBackgroundView = [[UIView alloc] init];
            _movieBackgroundView.alpha = 0.f;
            [_movieBackgroundView setBackgroundColor:[UIColor blackColor]];
        }
    }
    return self;
}

- (void)dealloc {
    // You would think that deallocating the movie controller would be enough,
    // but apparently it's a buggy piece of junk and you need to do this too
    // or it will continue downloading and playing the audio stream in the background

    //set contentUrl nil if it has some value otherwise it will cause crash
    //because controls are nil after reseting player
    if (self.contentURL)
        self.contentURL = nil;
    _delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

# pragma mark - Getters

- (BOOL)isFullscreen {
    return _movieFullscreen;
}

# pragma mark - Setters

- (void)setContentURL:(NSURL*)contentURL {
    if(!_controls) {
        [[NSException exceptionWithName:@"CLMoviePlayerController Exception" reason:@"Set contentURL after setting controls." userInfo:nil] raise];
    }
    _currentContentUrl = contentURL;
    _lastPlayedTime = -1;
    [super setContentURL:contentURL];
    [[NSNotificationCenter defaultCenter] postNotificationName:CLVideoPlayerContentURLDidChangeNotification object:nil];
}

- (void)setLastPlayedTime:(float)lastPlayedTime {
    _lastPlayedTime = lastPlayedTime;
    _startTime = lastPlayedTime;
}

- (void)setControls:(nullable CLVideoPlayerControls*)controls {
    if(_controls != controls) {
        _controls = controls;
        _controls.delegate = self;
        _controls.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        [self.view addSubview:_controls];
    }
}

- (void)setFrame:(CGRect)frame {
    [self.view setFrame:frame];
    [self.controls setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
}

- (void)setFullscreen:(BOOL)fullscreen {
    [self setFullscreen:fullscreen animated:YES withOrientation:[[UIApplication sharedApplication] statusBarOrientation] forceRotate:NO];
}

- (void)setFullscreen:(BOOL)fullscreen withOrientation:(UIInterfaceOrientation)orientation {
    [self setFullscreen:fullscreen animated:YES withOrientation:orientation forceRotate:NO];
}

- (void)setFullscreen:(BOOL)fullscreen animated:(BOOL)animated forceRotate:(BOOL)rotate {
    [self setFullscreen:fullscreen animated:animated withOrientation:UIInterfaceOrientationLandscapeLeft forceRotate:rotate];
}

- (void)setFullscreen:(BOOL)fullscreen withOrientation:(UIInterfaceOrientation) orientation animated:(BOOL)animated forceRotate:(BOOL)rotate {
    [self setFullscreen:fullscreen animated:animated withOrientation:orientation forceRotate:rotate];
}

- (void)setFullscreen:(BOOL)fullscreen animated:(BOOL)animated withOrientation:(UIInterfaceOrientation)deviceOrientation forceRotate:(BOOL)rotate {
    _movieFullscreen = fullscreen;
    if(fullscreen) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerWillEnterFullscreenNotification object:nil];

        UIWindow* keyWindow = [[UIApplication sharedApplication] keyWindow];

        if(!keyWindow) {
            keyWindow = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
        }

        UIView* container = keyWindow.rootViewController.view;
        if(CGRectEqualToRect(self.movieBackgroundView.frame, CGRectZero)) {
            [self.movieBackgroundView setFrame:container.bounds];
        }

        [container addSubview:self.movieBackgroundView];
        [UIView animateWithDuration:animated ? fullscreenAnimationDuration: 0.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.movieBackgroundView.alpha = 1.f;
        } completion:^(BOOL finished) {
            // self.view.alpha = 0.f;
            [self.movieBackgroundView addSubview:self.view];

            [self rotateMoviePlayerForOrientation:deviceOrientation animated:NO forceRotate:rotate completion:^{
                    [UIView animateWithDuration:animated ? fullscreenAnimationDuration: 0.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                            self.view.alpha = 1.f;
                        } completion:^(BOOL finished) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerDidEnterFullscreenNotification object:nil];
                        }];
                }];
        }];
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerWillExitFullscreenNotification object:nil];

        // ios 8 player fix

        if(IS_IOS8) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
        }
        else {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
        }

        [UIView animateWithDuration:animated ? fullscreenAnimationDuration: 0.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.view.alpha = 0.f;
        } completion:^(BOOL finished) {
            if([self.delegate respondsToSelector:@selector(moviePlayerWillMoveFromWindow)]) {
                [self.delegate moviePlayerWillMoveFromWindow];
            }
            self.view.alpha = 1.f;
            [UIView animateWithDuration:animated ? fullscreenAnimationDuration: 0.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                    self.movieBackgroundView.alpha = 0.f;
                } completion:^(BOOL finished) {
                    [self.movieBackgroundView removeFromSuperview];
                    [[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerDidExitFullscreenNotification object:nil];
                }];
        }];
    }
}

#pragma mark - Notifications

- (void)videoLoadStateChanged:(NSNotification*)note {
    switch(self.loadState) {
        case MPMovieLoadStatePlayable :
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(movieTimedOut) object:nil];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
        default :
            break;
    }
}

- (void)rotateMoviePlayerForOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated forceRotate:(BOOL)rotate completion:(void (^)(void))completion {
    CGFloat angle;
    CGSize windowSize;

    if(IS_IOS8) {
        windowSize = [UIScreen mainScreen].bounds.size;         // ios 8 player fix
    }
    else {
        windowSize = [UIApplication sizeInOrientation:orientation];
    }

    CGRect backgroundFrame;
    CGRect movieFrame;
    switch(orientation) {
        case UIInterfaceOrientationPortrait:
            angle = 0;
            backgroundFrame = CGRectMake(0, 0, windowSize.width, windowSize.height);
            movieFrame = CGRectMake(0, 0, backgroundFrame.size.width, backgroundFrame.size.height);
            
            break;

        case UIInterfaceOrientationLandscapeRight:
            angle = 0;

            if(IS_IOS8) {
                backgroundFrame = CGRectMake(0, 0, windowSize.width, windowSize.height);
                movieFrame = CGRectMake(0, 0, backgroundFrame.size.width, backgroundFrame.size.height);
            }
            else {
                backgroundFrame = CGRectMake(movieBackgroundPadding, -movieBackgroundPadding, windowSize.height + movieBackgroundPadding * 2, windowSize.width + movieBackgroundPadding * 2);
                movieFrame = CGRectMake(movieBackgroundPadding, movieBackgroundPadding, backgroundFrame.size.height - movieBackgroundPadding * 2, backgroundFrame.size.width - movieBackgroundPadding * 2);
            }

            break;

        case UIInterfaceOrientationLandscapeLeft:
            angle = 0;

            if(IS_IOS8) {
                backgroundFrame = CGRectMake(0, 0, windowSize.width, windowSize.height);
                movieFrame = CGRectMake(0, 0, backgroundFrame.size.width, backgroundFrame.size.height);
            }
            else {
                backgroundFrame = CGRectMake(movieBackgroundPadding, -movieBackgroundPadding, windowSize.height + movieBackgroundPadding * 2, windowSize.width + movieBackgroundPadding * 2);

                movieFrame = CGRectMake(movieBackgroundPadding, movieBackgroundPadding, backgroundFrame.size.height - movieBackgroundPadding * 2, backgroundFrame.size.width - movieBackgroundPadding * 2);
            }

            break;

        default:
            angle = 0.f;
            backgroundFrame = CGRectMake(movieBackgroundPadding, movieBackgroundPadding, windowSize.width + movieBackgroundPadding * 2, windowSize.height + movieBackgroundPadding * 2);
            movieFrame = CGRectMake(movieBackgroundPadding, movieBackgroundPadding, backgroundFrame.size.width - movieBackgroundPadding * 2, backgroundFrame.size.height - movieBackgroundPadding * 2);
            break;
    }

    // Used to rotate the view on Fulscreen button click
    // Rotate it forcefully as the orientation is on the UIDeviceOrientation
    if(rotate && orientation == UIInterfaceOrientationLandscapeLeft) {
        angle = M_PI_2; // MOB-1053
        backgroundFrame = CGRectMake(0, 0, windowSize.width, windowSize.height);
        movieFrame = CGRectMake(0, 0, backgroundFrame.size.height, backgroundFrame.size.width);
    }
    else if (rotate && orientation == UIInterfaceOrientationLandscapeRight) {
        angle = -M_PI_2; // MOB-1053
        backgroundFrame = CGRectMake(0, 0, windowSize.width, windowSize.height);
        movieFrame = CGRectMake(0, 0, backgroundFrame.size.height, backgroundFrame.size.width);
    }

    if(animated) {
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.movieBackgroundView.transform = CGAffineTransformMakeRotation(angle);
            self.movieBackgroundView.frame = backgroundFrame;
            [self setFrame:movieFrame];
        } completion:^(BOOL finished) {
            if(completion) {
                completion();
            }
        }];
    }
    else {
        self.movieBackgroundView.transform = CGAffineTransformMakeRotation(angle);
        self.movieBackgroundView.frame = backgroundFrame;
        [self setFrame:movieFrame];
        if(completion) {
            completion();
        }
    }
}

# pragma mark - Internal Methods

- (void)play {
    [super play];
    //remote file
    if(![self.contentURL.scheme isEqualToString:@"file"] && self.loadState == MPMovieLoadStateUnknown) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(movieTimedOut) object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoLoadStateChanged:) name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
        [self performSelector:@selector(movieTimedOut) withObject:nil afterDelay:60];
    }
}

- (void)stop {
    [self saveLastPlayedTime];
    [super stop];
}

- (void)pause {
    [self saveLastPlayedTime];
    [super pause];
}

- (void)movieTimedOut {
    if(!(self.loadState & MPMovieLoadStatePlayable) || !(self.loadState & MPMovieLoadStatePlaythroughOK)) {
        [self stop];
        if([self.delegate respondsToSelector:@selector(movieTimedOut)]) {
            [self.delegate performSelector:@selector(movieTimedOut)];
        }
    }
}

- (void)saveLastPlayedTime {
    if(_currentContentUrl) {
        if([self.delegate respondsToSelector:@selector(playerDidStopPlaying:atPlayBackTime:)]) {
            [self.delegate playerDidStopPlaying:_currentContentUrl atPlayBackTime:self.currentPlaybackTime];
        }
    }
}

- (void) videoPlayerTapped:(id) sender {
    if([self.delegate respondsToSelector:@selector(videoPlayerTapped:)]) {
        [self.delegate videoPlayerTapped:sender];
    }
}

- (void)transcriptLoaded:(NSArray *)transcript {
    if([self.delegate respondsToSelector:@selector(transcriptLoaded:)]) {
        [self.delegate transcriptLoaded:transcript];
    }
}

- (void)resetMoviePlayer {
    [self.controls resetControls];
    self.controls = nil;
    [self stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.movieBackgroundView removeFromSuperview];
    [self.view removeFromSuperview];
}

/*

 Fixes for iOS 8

 https://github.com/alobi/ALMoviePlayerController/issues/17

 I have the same orientation problem with one of my app. Here's the fix:

 In - (void)setFullscreen:(BOOL)fullscreen animated:(BOOL)animated, change UIApplicationWillChangeStatusBarOrientationNotification to UIApplicationDidChangeStatusBarOrientationNotification
 In - (void)rotateMoviePlayerForOrientation: change CGSize windowSize = [UIApplication sizeInOrientation:orientation]; to CGSize windowSize =[UIScreen mainScreen].bounds.size;

 Delete self.movieBackgroundView.transform = CGAffineTransformMakeRotation(angle); in if(animated) and else
 */

@end
