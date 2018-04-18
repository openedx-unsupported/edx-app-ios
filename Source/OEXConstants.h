//
//  OEXConstants.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 22/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#ifndef edXVideoLocker_edXConstants_h
#define edXVideoLocker_edXConstants_h

typedef NS_ENUM (NSUInteger, OEXDownloadState) {
    OEXDownloadStateNew = 0,
    OEXDownloadStatePartial,
    OEXDownloadStateComplete,
};

typedef NS_ENUM (NSUInteger, OEXPlayedState) {
    OEXPlayedStateUnwatched = 0,
    OEXPlayedStatePartiallyWatched,
    OEXPlayedStateWatched
};

typedef NS_ENUM (NSUInteger, OEXVideoState) {
    OEXVideoStateLoading = 101,
    OEXVideoStatePlay,
    OEXVideoStatePause,
    OEXVideoStateStop
};

/**Video player speeds*/
typedef NS_ENUM(NSUInteger, OEXVideoSpeed) {
    OEXVideoSpeedDefault, //1.0x
    OEXVideoSpeedSlow, // .5x
    OEXVideoSpeedFast, // 1.5x
    OEXVideoSpeedXFast, // 2x
};

//Wifi only Key
#define USERDEFAULT_KEY_WIFIONLY @"download on wifi only"

// Registration
#define NOTIFICATION_REGISTRATION_FORM_FIELD_VALUE_DID_CHANGE @"RegistrationFormFieldValueDidChange"

//courses and videos
#define CAV_KEY_COURSE @"course"
#define CAV_KEY_VIDEOS @"videos"
#define CAV_KEY_RECENT_VIDEOS @"sortedVideos"
#define CAV_KEY_VIDEOS_SIZE @"videoSize"

//Download complete notification
#define VIDEO_DL_COMPLETE_N_TASK @"video_Download_otification_task"

#define DL_COMPLETE @"Download Complete"
#define DL_COMPLETE_N_TASK @"Download Complete notification task"

#define FL_MESSAGE @"Floating message"
#define FL_ARRAY @"Array"


//JSON URLs
#define NOTIFICATION_URL_RESPONSE @"URL_Response"
#define NOTIFICATION_KEY_URL @"Original_URL"
#define NOTIFICATION_KEY_STATUS @"Status"
#define NOTIFICATION_KEY_OFFLINE @"Offline"
#define NOTIFICATION_VALUE_OFFLINE_YES @"YES"
#define NOTIFICATION_VALUE_OFFLINE_NO @"NO"
#define NOTIFICATION_VALUE_URL_STATUS_FAILED @"Falied"
#define NOTIFICATION_VALUE_URL_STATUS_SUCCESS @"Success"

#define NOTIFICATION_VALUE_URL_LASTACCESSED @"LastAccessedURL"

// Closed Captioning
#define CC_TRANSCRIPT_OBJECT @"TranscriptObject"
#define CC_SELECTED_INDEX @"SelectedIndex"

#define PERSIST_CC @"SelectedCC"
#define PERSIST_PLAYBACKSPEED @"VideoPlaybackSpeed"

#define KEY_SET_CC @"ClosedCaption"
#define KEY_SET_CC_URL @"ClosedCaptionURL"
#define KEY_SET_PLAYBACKSPEED @"PlaybackSpeed"

// Video player Prev/Next button
#define NOTIFICATION_VIDEO_PLAYER_NEXT @"VideoPlayerNext"
#define NOTIFICATION_VIDEO_PLAYER_PREVIOUS @"VideoPlayerPrevious"

#define NOTIFICATION_HIDE_PREV_NEXT @"hidePrevNext"
//#define KEY_ONE_VIDEO @"OneVideo"
#define KEY_DISABLE_PREVIOUS @"DisablePrev"
#define KEY_DISABLE_NEXT @"DisableNext"

// For Transcript

#define LAST_ACCESSED_SUBSECTION_ID @"SubsectionID"
#define LAST_ACCESSED_SUBSECTION_NAME @"SubsectionName"

#define NOTIFICATION_APP_ENTER_FOREGROUND @"EnterForeground"

//Post method for API calls
#define OEXHTTPMethodPOST @"POST"

//Animation
#define ANI_DURATION 1.0
#define ANI_ERROR_TIMEOUT 5.0

#define PROGRESSBAR_PROGRESS_TINT_COLOR [UIColor colorWithRed:126.0 / 255.0 green:199.0 / 255.0 blue:143.0 / 255.0 alpha:1.0]

#define PROGRESSBAR_TRACK_TINT_COLOR [UIColor colorWithRed:223.0 / 255.0 green:242.0 / 255.0 blue:228.0 / 255.0 alpha:1.0]

#define SELECTED_CELL_COLOR [UIColor colorWithRed:(float)41 / 255 green:(float)158 / 255 blue:(float)215 / 255 alpha:0.2f]

#define GREY_COLOR [UIColor colorWithRed:226.0 / 255.0 green:227.0 / 255.0 blue:229.0 / 255.0 alpha:1.0]

// Open in browser
#define OPEN_IN_BROWSER_HEIGHT 44

//Animation Speed
#define ANIMATION_DURATION 0.35

//Standard Video Aspect Ratio
#define STANDARD_VIDEO_ASPECT_RATIO  0.563

#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height

#define IS_IPHONE_4 ( [ [ UIScreen mainScreen ] bounds ].size.height == 480 )
#define IS_IPHONE_5 ( [ [ UIScreen mainScreen ] bounds ].size.height == 568 )
#define IS_IPHONE_6 ( [ [ UIScreen mainScreen ] bounds ].size.height == 667 )
#define IS_IPHONE_6_PLUS ( [ [ UIScreen mainScreen ] bounds ].size.height == 736 )

#endif
