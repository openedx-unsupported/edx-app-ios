//
//  CLVideoPlayerControls.h
//  CLMoviePlayer
//
//  Created by Jotiram Bhagat on 24/06/14.
//  Copyright (c) 2014-2016 Jotiram Bhagat. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@class CLVideoPlayer;
@class OEXHelperVideoDownload;

typedef enum
{
    /** Controls will appear in a bottom bar */
    CLVideoPlayerControlsStyleEmbedded,

    /** Controls will appear in a top bar and bottom bar */
    CLVideoPlayerControlsStyleFullscreen,

    /** Controls will appear as CLVideoPlayerControlsStyleFullscreen when in fullscreen and CLVideoPlayerControlsStyleEmbedded at all other times */
    CLVideoPlayerControlsStyleDefault,

    /** Controls will not appear */
    CLVideoPlayerControlsStyleNone,
} CLVideoPlayerControlsStyle;

typedef enum
{
    /** Controls are not doing anything */
    CLVideoPlayerControlsStateIdle,

    /** Controls are waiting for movie to finish loading */
    CLVideoPlayerControlsStateLoading,

    /** Controls are ready to play and/or playing */
    CLVideoPlayerControlsStateReady,
} CLVideoPlayerControlsState;

extern NSString* const CLVideoPlayerkIndex;
extern NSString* const CLVideoPlayerkStart;
extern NSString* const CLVideoPlayerkEnd;
extern NSString* const CLVideoPlayerkText;

@protocol CLVideoPlayerControlsDelegate <NSObject>
- (void) videoPlayerTapped:(id) sender;
- (void) transcriptLoaded:(NSArray *)transcript;
@end


@interface CLVideoPlayerControls : UIView

@property (strong, nonatomic) OEXHelperVideoDownload* video;

/**
 The style of the controls. Can be changed on the fly.

 Default value is CLVideoPlayerControlsStyleDefault
 */
@property (nonatomic, assign) CLVideoPlayerControlsStyle style;

/**
 The state of the controls.
 */
@property (nonatomic, readonly) CLVideoPlayerControlsState state;

/**
 The color of the control bars.

 Default value is black with a hint of transparency.
 */
@property (nonatomic, strong) UIColor* barColor;

/**
 The height of the control bars.

 Default value is 70.f for iOS7+ and 50.f for previous versions.
 */
@property (nonatomic, assign) CGFloat barHeight;

/**
 The amount of time that the controls should stay on screen before automatically hiding.

 The default value is set using the constant OEXVideoControlsFadeDelay in the implementation file.
 */
@property (nonatomic, assign) NSTimeInterval fadeDelay;

/**
 The rate at which the movie should fastforward or rewind.

 Default value is 3x.
 */
@property (nonatomic, assign) float seekRate;

/**
 Should the time-remaining number decrement as the video plays?

 Default value is NO.
 */
@property (nonatomic) BOOL timeRemainingDecrements;

/**
 Are the controls currently showing on screen?
 */
@property (nonatomic, readonly, getter = isShowing) BOOL showing;

/**
 Checks if the parent viewController is at the top of the stack
 */
@property (nonatomic) BOOL isVisibile;

/// Are the next/previous buttons hidden
@property (assign, nonatomic) BOOL hidesNextPrev;

/**
 The default initializer method. The parameter may not be nil.
 */
- (id)initWithMoviePlayer:(CLVideoPlayer*)moviePlayer style:(CLVideoPlayerControlsStyle)style;

- (void)resetControls;

- (void)hideOptionsAndValues;

- (void)setCurrentPlaybackTimeFromTranscript:(NSTimeInterval )time;

// For Closed Captioning
@property (nonatomic, weak, nullable) CLVideoPlayer* moviePlayer;

@property (nonatomic, assign) float playbackRate;

@property (nonatomic, weak) id <CLVideoPlayerControlsDelegate> delegate;


@end

NS_ASSUME_NONNULL_END
