//
//  CLVideoPlayerControls.m
//  CLMoviePlayer
//
//  Created by Jotiram Bhagat on 24/06/14.
//  Copyright (c) 2014 Jotiram Bhagat. All rights reserved.
//

#import "CLVideoPlayerControls.h"

#import <CoreMedia/CoreMedia.h>
#import <objc/runtime.h>

#import "CLButton.h"
#import "CLVideoPlayer.h"
#import "OEXCustomSlider.h"
#import "OEXTranscriptsData.h"
#import "OEXInterface.h"
#import "OEXHelperVideoDownload.h"
#import "OEXAuthentication.h"
#import "OEXClosedCaptionTableViewCell.h"
#import "OEXUserDetails.h"
#import "OEXVideoSummary.h"

static NSString* const kIndex = @"kIndex";
static NSString* const kStart = @"kStart";
static NSString* const kEnd = @"kEnd";
static NSString* const kText = @"kText";

static const NSTimeInterval CLVideoSkipBackwardsDuration = 30;

@interface CLVideoPlayerControls ()
@property(nonatomic) MPMoviePlaybackState stateBeforeSeek;
@property(nonatomic) BOOL loadingContentUrl;
@end

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

@interface CLMoviePlayerControlsBar : UIView

@property (nonatomic, strong) UIColor* color;

@end

static const CGFloat activityIndicatorSize = 40.f;
static const CGFloat iPhoneScreenPortraitWidth = 320.f;

@interface CLVideoPlayerControls () <CLButtonDelegate, UITableViewDelegate, UITableViewDataSource>
{
    NSMutableData* receivedData;
    NSURLConnection* connectionSRT;

    @private
    int windowSubviews;
}
@property (nonatomic, assign) CLVideoPlayerControlsState state;
@property (nonatomic, getter = isShowing) BOOL showing;

@property (nonatomic, strong) NSTimer* durationTimer;

@property (nonatomic, strong) UIView* activityBackgroundView;
@property (nonatomic, strong) UIActivityIndicatorView* activityIndicator;

@property (nonatomic, strong) CLMoviePlayerControlsBar* topBar;
@property (nonatomic, strong) CLMoviePlayerControlsBar* bottomBar;
@property (nonatomic, strong) OEXCustomSlider* durationSlider;
@property (nonatomic, strong) CLButton* playPauseButton;
@property (nonatomic, strong) MPVolumeView* volumeView;
@property (nonatomic, strong) CLButton* fullscreenButton;
@property (nonatomic, strong) UILabel* timeElapsedLabel;
@property (nonatomic, strong) UILabel* timeRemainingLabel;
@property (nonatomic, strong) UILabel* videoTitleLabel;
@property (nonatomic, strong) CLButton* seekForwardButton;
@property (nonatomic, strong) CLButton* rewindButton;

@property (nonatomic, strong) CLButton* btnSettings;
@property (nonatomic, strong) UIView* view_OptionsOverlay;
@property (nonatomic, strong) UIView* view_OptionsInner;
@property (nonatomic, strong) UITableView* table_Options;
@property (nonatomic, strong) UITableView* table_Values;
@property (nonatomic, strong) UIButton* btnCancel;
@property (nonatomic, strong) CLButton* btnPrevious;
@property (nonatomic, strong) CLButton* btnNext;
@property (nonatomic, strong) CLButton* btnLMS;
@property (nonatomic, strong) NSMutableArray* arr_Values;
@property (nonatomic, strong) NSMutableArray* arr_SettingOptions;
@property (nonatomic, assign) NSInteger selectedCCOption;
@property (nonatomic, strong) OEXTranscriptsData* objTranscript;
@property (nonatomic, weak) OEXInterface* dataInterface;

@property(nonatomic, assign) BOOL seeking;
@property (nonatomic, assign) BOOL hideNext;
@property (nonatomic, assign) BOOL hidePrevious;

@property (nonatomic, strong) CLButton* scaleButton;
@property (nonatomic, strong) NSTimer* bufferedTimer;

@property (nonatomic, strong) UISwipeGestureRecognizer* leftSwipeGestureRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer* rightSwipeGestureRecognizer;

#pragma mark - Properties
@property (strong, nonatomic) NSMutableDictionary* subtitlesParts;
@property (strong, nonatomic) NSTimer* subtitleTimer;
@property (strong, nonatomic) UILabel* subtitleLabel;

#pragma mark - Private methods
- (void)showSubtitles:(BOOL)show;
- (void)parseClosedCaptioningString:(NSString*)string parsed:(void (^)(BOOL parsed, NSError* error))completion;
- (NSTimeInterval)getTimeFromString:(NSString*)yimeString;
- (void)searchAndDisplaySubtitle;

#pragma mark - Notifications
- (void)orientationDidChange:(NSNotification*)notification;

#pragma mark - For seek event
@property (nonatomic, assign) NSTimeInterval startTime;
@property (nonatomic, assign) NSTimeInterval stopTime;

@end

@implementation CLVideoPlayerControls

- (void)setPlayerControlAccessibilityID {
    _videoTitleLabel.accessibilityLabel = @"lbVideoTitle";
    _durationSlider.accessibilityLabel = @"sliderDuration";
    _timeElapsedLabel.accessibilityLabel = @"lbTime";
    _btnPrevious.accessibilityLabel = @"btnPrevious";
    _btnNext.accessibilityLabel = @"btnNext";
    _rewindButton.accessibilityLabel = @"btnRewind";
    _playPauseButton.accessibilityLabel = @"btnPlayPause";
    _btnSettings.accessibilityLabel = @"btnSettings";
    _btnLMS.accessibilityLabel = @"btnLMS";
    _fullscreenButton.accessibilityLabel = @"btnFullScreen";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
	// Return the number of sections.
    return 1;
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    UIView* viewMain = nil;

    if(tableView == self.table_Values) {
        viewMain = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        viewMain.backgroundColor = GREY_COLOR;

        UILabel* chapTitle = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 280, 44)];

        if(self.selectedCCOption == 0) {
            chapTitle.text = @"Closed Captions";
        }
        else if(self.selectedCCOption == 1) {
            chapTitle.text = @"Video Speed";
        }
        chapTitle.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
        chapTitle.textColor = [UIColor blackColor];
        [viewMain addSubview:chapTitle];
    }

    return viewMain;
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    if(tableView == self.table_Values) {
        return 44;
    }
    else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	// Return the number of rows in the section.
    if(tableView == self.table_Options) {
        return [self.arr_SettingOptions count];
    }
    else if(tableView == self.table_Values) {
        return [self.arr_Values count];
    }

    return 2;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 44;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    OEXClosedCaptionTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"CustomCell" forIndexPath:indexPath];

	// To show blue selection.
    UIView* bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = SELECTED_CELL_COLOR;
    bgColorView.layer.masksToBounds = YES;
    cell.selectedBackgroundView = bgColorView;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    cell.lbl_Title.font = [UIFont fontWithName:@"OpenSans" size:12.f];

    [cell.viewDisable setBackgroundColor:[UIColor whiteColor]];

    if(tableView == self.table_Options) {
        [bgColorView removeFromSuperview];

        cell.lbl_Title.text = [self.arr_SettingOptions objectAtIndex:indexPath.row];
        cell.userInteractionEnabled = YES;
        cell.backgroundColor = [UIColor whiteColor];

        if(indexPath.row == 0) {
            if([self videoContainsNoTranscript]) {
                [cell.viewDisable setBackgroundColor:[UIColor colorWithRed:(float)234 / 255 green:(float)234 / 255 blue:(float)237 / 255 alpha:1.0]];
                cell.userInteractionEnabled = NO;
            }
        }

#ifdef __IPHONE_8_0
        if(IS_IOS8) {
            [cell setLayoutMargins:UIEdgeInsetsZero];
        }
#endif
    }
    else if(tableView == self.table_Values) {
        if(self.selectedCCOption == 0) {
		// To retain the selected blue color on selected cell
            if(indexPath.row == _dataInterface.selectedCCIndex) {
                [cell addSubview:bgColorView];
            }
            else {
                [bgColorView removeFromSuperview];
            }
        }
        else if(self.selectedCCOption == 1) {
		// To retain the selected blue color on selected cell
            if(indexPath.row == _dataInterface.selectedVideoSpeedIndex) {
                [cell addSubview:bgColorView];
            }
            else {
                [bgColorView removeFromSuperview];
            }
        }

        cell.backgroundColor = [UIColor whiteColor];

        cell.lbl_Title.text = [self.arr_Values objectAtIndex:indexPath.row];
    }

#ifdef __IPHONE_8_0
    if(IS_IOS8) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
#endif

    return cell;
}

#pragma mark TableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    if(tableView == self.table_Options) {
        _selectedCCOption = indexPath.row;

        self.table_Options.hidden = YES;

        switch(indexPath.row)
        {
            case 0:

                [self addCCTableValues];

                break;

            case 1:
                self.arr_Values = [[NSMutableArray alloc] initWithObjects:@"0.5x", @"1.0x", @"1.5x", @"2.0x", nil];

                break;

            default:
                break;
        }

	// Mob - 599 - Flexible popup
        [self changeCCPopUpSize];

        if(self.style == CLVideoPlayerControlsStyleFullscreen || (self.style == CLVideoPlayerControlsStyleDefault && self.moviePlayer.isFullscreen)) {
            self.table_Values.hidden = NO;
            self.view_OptionsInner.hidden = NO;
        }
        else if(self.style == CLVideoPlayerControlsStyleEmbedded || (self.style == CLVideoPlayerControlsStyleDefault && !self.moviePlayer.isFullscreen)) {
		// notify that the view should open in portrait mode
            [self didHideTables:YES];
            [_btnSettings setImage:[UIImage imageNamed:@"ic_settings.png"] forState:UIControlStateNormal];
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_OPEN_CC_PORTRAIT object:self userInfo:@{CC_VALUE_ARRAY: self.arr_Values, CC_TRANSCRIPT_OBJECT:self.objTranscript, CC_SELECTED_INDEX:[NSString stringWithFormat:@"%ld", (long)self.selectedCCOption]}];
        }

        [self.table_Options deselectRowAtIndexPath:indexPath animated:YES];
        [self.table_Values reloadData];
    }
    else if(tableView == self.table_Values) {
        [self didHideTables:YES];

        if(self.selectedCCOption == 0) {
            _dataInterface.selectedCCIndex = indexPath.row;

            NSString* strValue = [self.arr_Values objectAtIndex:indexPath.row];
            NSString* strLang = [[NSString alloc] init];

            if([strValue isEqualToString:@"Chinese"]) {
                strLang = @"zh";
                [self activateSubTitles:self.objTranscript.ChineseURLFilePath WithFileDownloadURL:self.objTranscript.ChineseDownloadURLString];
            }
            else if([strValue isEqualToString:@"English"]) {
                strLang = @"en";
                [self activateSubTitles:self.objTranscript.EnglishURLFilePath WithFileDownloadURL:self.objTranscript.EnglishDownloadURLString];
            }
            else if([strValue isEqualToString:@"German"]) {
                strLang = @"de";
                [self activateSubTitles:self.objTranscript.GermanURLFilePath WithFileDownloadURL:self.objTranscript.GermanDownloadURLString];
            }
            else if([strValue isEqualToString:@"Portuguese"]) {
                strLang = @"pt";
                [self activateSubTitles:self.objTranscript.PortugueseURLFilePath WithFileDownloadURL:self.objTranscript.PortugueseDownloadURLString];
            }
            else if([strValue isEqualToString:@"Spanish"]) {
                strLang = @"es";
                [self activateSubTitles:self.objTranscript.SpanishURLFilePath WithFileDownloadURL:self.objTranscript.SpanishDownloadURLString];
            }
            else if([strValue isEqualToString:@"French"]) {
                strLang = @"fr";
                [self activateSubTitles:self.objTranscript.FrenchURLFilePath WithFileDownloadURL:self.objTranscript.FrenchDownloadURLString];
            }

		// Set the language to persist
            [OEXInterface setCCSelectedLanguage:strValue];

            if(self.video.summary.videoID) {
                [[OEXAnalytics sharedAnalytics] trackTranscriptLanguage: self.video.summary.videoID
                 CurrentTime: [self getMoviePlayerCurrentTime]
                 Language: strLang
                 CourseID: self.video.course_id
                 UnitURL: self.video.summary.unitURL];
            }
        }
        else if(self.selectedCCOption == 1) {
            _dataInterface.selectedVideoSpeedIndex = indexPath.row;

            NSString* oldSpeed = [NSString stringWithFormat:@"%.1f", self.playbackRate];

            switch(indexPath.row)
            {
                case 0:
                    self.playbackRate = 0.5;
                    break;

                case 1:
                    self.playbackRate = 1.0;
                    break;

                case 2:
                    self.playbackRate = 1.5;
                    break;

                case 3:
                    self.playbackRate = 2.0;
                    break;

                default:
                    break;
            }

            [self.moviePlayer setCurrentPlaybackRate:_playbackRate];

            if(self.video.summary.videoID) {
                ELog(@" did select ====== trackVideoSpeed");
                [[OEXAnalytics sharedAnalytics] trackVideoSpeed: self.video.summary.videoID
                 CurrentTime: [self getMoviePlayerCurrentTime]
                 CourseID: self.video.course_id
                 UnitURL: self.video.summary.unitURL
                 OldSpeed: oldSpeed
                 NewSpeed: [NSString stringWithFormat:@"%.1f", self.playbackRate]];
            }
        }

        [self hideControls:nil];
    }
}

- (BOOL)videoContainsNoTranscript {
    BOOL status = NO;

    if(!self.objTranscript.ChineseURLFilePath && !self.objTranscript.EnglishURLFilePath && !self.objTranscript.GermanURLFilePath && !self.objTranscript.PortugueseURLFilePath && !self.objTranscript.SpanishURLFilePath && !self.objTranscript.FrenchURLFilePath) {
        status = YES;
    }

    return status;
}

- (void)callPortraitSubtitles:(NSNotification*)notification {
    NSDictionary* dict = notification.userInfo;

    self.btnSettings.selected = NO;
    [_btnSettings setImage:[UIImage imageNamed:@"ic_settings.png"] forState:UIControlStateNormal];

    NSString* Key = [[NSString alloc] init];
    Key = [[dict allKeys] lastObject];

    if([Key isEqualToString:KEY_SET_PLAYBACKSPEED]) {
        NSString* oldSpeed = [NSString stringWithFormat:@"%.1f", self.playbackRate];

        self.playbackRate = [[dict objectForKey:KEY_SET_PLAYBACKSPEED] floatValue];
        [self.moviePlayer setCurrentPlaybackRate:self.playbackRate];
        [self.moviePlayer play];

        ELog(@" callPortraitSubtitles ====== trackVideoSpeed");
        [[OEXAnalytics sharedAnalytics] trackVideoSpeed: self.video.summary.videoID
         CurrentTime: [self getMoviePlayerCurrentTime]
         CourseID: self.video.course_id
         UnitURL: self.video.summary.unitURL
         OldSpeed: oldSpeed
         NewSpeed: [NSString stringWithFormat:@"%.1f", self.playbackRate]];
    }
    else {
        if([[dict objectForKey:KEY_SET_CC] isEqualToString:@"off"]) {
            [self cancelBtnClicked:nil];
        }
        else {
            [self activateSubTitles:[dict objectForKey:KEY_SET_CC] WithFileDownloadURL:[dict objectForKey:KEY_SET_CC_URL]];
        }
    }
}

- (void)didHideTables:(BOOL)hide {
    if(self.table_Options && self.table_Values) {
        self.view_OptionsOverlay.hidden = hide;
        self.view_OptionsInner.hidden = hide;
        self.table_Options.hidden = hide;
        self.table_Values.hidden = hide;
    }
}

#pragma mark - Subtitle

- (void)activateSubTitles:(NSString*)filePath WithFileDownloadURL:(NSString*)URLString {
	// Send the path of the file saved to Sandbox

    [self getClosedCaptioningFileAtPath:filePath DownloadURL:URLString
     completion:^(BOOL finished) {
	// Activate subtitles
         [self showSubtitles];

	// Analytics SHOW TRANSCRIPT
         [self analyticsShowTranscript];
     } failure:^(NSError* error) {
     }];
}

#pragma mark - Methods

- (NSTimeInterval)getMoviePlayerCurrentTime {
    NSTimeInterval currentTime = self.moviePlayer.currentPlaybackTime;
    if(isnan(currentTime)) {
        currentTime = 0;
    }
    return currentTime;
}

- (void)getClosedCaptioningFileAtPath:(NSString*)localFile DownloadURL:(NSString*)URLString completion:(void (^)(BOOL finished))success failure:(void (^)(NSError* error))failure {
	// Error
    NSError* error = nil;
    NSString* subtitleString = [[NSString alloc] init];

	// File to string
    if([[NSFileManager defaultManager] fileExistsAtPath:localFile]) {
	// File to string
        subtitleString = [NSString stringWithContentsOfFile:localFile
                          encoding:NSUTF8StringEncoding
                          error:&error];

        subtitleString = [subtitleString stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
    }
    else {
        [_dataInterface downloadWithRequestString:URLString forceUpdate:NO];
    }

    if(error && failure != NULL) {
        failure(error);
        return;
    }

	// Parse and show text
    [self readClosedCaptioningString:subtitleString completion:success failure:failure];
}

- (void)readClosedCaptioningString:(NSString*)srtString completion:(void (^)(BOOL finished))success failure:(void (^)(NSError* error))failure {
    [self parseClosedCaptioningString:srtString
     parsed:^(BOOL parsed, NSError* error) {
         if(!error && success != NULL) {
             if(success != NULL) {
                 success(YES);
             }
         }
         else if(error && failure != NULL) {
             if(failure != NULL) {
                 failure(error);
             }
         }
     }];
}

- (void)showSubtitles:(BOOL)show {
	// Hide label
    self.subtitleLabel.hidden = !show;
}

- (void)showSubtitles {
    [self showSubtitles:YES];
}

- (void)hideSubtitles {
    [self showSubtitles:NO];
}

#pragma mark - CC Private methods

- (void)parseClosedCaptioningString:(NSString*)string parsed:(void (^)(BOOL parsed, NSError* error))completion {
	// Create Scanner
    NSScanner* scanner = [NSScanner scannerWithString:string];

	// Subtitles parts
    self.subtitlesParts = [NSMutableDictionary dictionary];

	// Search for members
    while(!scanner.isAtEnd) {
	// Variables
        NSString* indexString;
        [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet]
         intoString:&indexString];

        NSString* startString;
        [scanner scanUpToString:@" --> " intoString:&startString];
        [scanner scanString:@"-->" intoString:NULL];

        NSString* endString;
        [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet]
         intoString:&endString];

        NSString* textString;

        [scanner scanUpToString:@"\n\n" intoString:&textString];
        textString = [textString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

	//RAHUL
        if([textString rangeOfString:@" --> "].location != NSNotFound) {
            NSArray* arrParse = [textString componentsSeparatedByString:@"\n"];
            textString = [arrParse lastObject];
        }

	// Regular expression to replace tags
        NSError* error = nil;
        NSRegularExpression* regExp = [NSRegularExpression regularExpressionWithPattern:@"[<|\\{][^>|\\^}]*[>|\\}]"
                                       options:NSRegularExpressionCaseInsensitive
                                       error:&error];
        if(error) {
            completion(NO, error);
            return;
        }

        textString = [regExp stringByReplacingMatchesInString:textString.length > 0 ? textString : @""
                      options:0
                      range:NSMakeRange(0, textString.length)
                      withTemplate:@""];

	// Temp object
        NSTimeInterval startInterval = [self getTimeFromString:startString];
        NSTimeInterval endInterval = [self getTimeFromString:endString];
        NSDictionary* tempInterval = @{
            kIndex : indexString,
            kStart : @(startInterval),
            kEnd : @(endInterval),
            kText : textString ? textString : @""
        };
        [self.subtitlesParts setObject:tempInterval
         forKey:indexString];
    }

    if(completion != NULL) {
        completion(YES, nil);
    }
}

- (NSTimeInterval)getTimeFromString:(NSString*)timeString {
    NSScanner* scanner = [NSScanner scannerWithString:timeString];

    int h, m, s, c;
    [scanner scanInt:&h];
    [scanner scanString:@":" intoString:NULL];
    [scanner scanInt:&m];
    [scanner scanString:@":" intoString:NULL];
    [scanner scanInt:&s];
    [scanner scanString:@"," intoString:NULL];
    [scanner scanInt:&c];

    return (h * 3600) + (m * 60) + s + (c / 1000.0);
}

- (void)searchAndDisplaySubtitle {
    if(![OEXInterface getCCSelectedLanguage]) {
        return;
    }

	// Search for timeInterval
    @autoreleasepool {
        NSPredicate* initialPredicate = [NSPredicate predicateWithFormat:@"(%@ >= %K) AND (%@ <= %K)", @(self.moviePlayer.currentPlaybackTime), kStart, @(self.moviePlayer.currentPlaybackTime), kEnd];

        NSArray* objectsFound = [[self.subtitlesParts allValues] filteredArrayUsingPredicate:initialPredicate];
        NSDictionary* lastFounded = (NSDictionary*)[objectsFound lastObject];
	// Show text
        if(lastFounded) {
		// If the text contains the --> this means the previous time slot has no text to it
		// so to resolve that check --> and make the string blank.
            if([[lastFounded objectForKey:kText] rangeOfString:@"-->"].location != NSNotFound) {
                self.subtitleLabel.text = @"";
                self.subtitleLabel.hidden = YES;
            }
            else {
		// Get text
                self.subtitleLabel.text = [lastFounded objectForKey:kText];
                self.subtitleLabel.hidden = NO;
		// Label position
                [self setSubtitleLabelFrame];
            }
        }
        else {
            self.subtitleLabel.text = @"";
            self.subtitleLabel.hidden = YES;
        }
    }
}

- (void)setSubtitleLabelFrame {
    CGFloat Y_offset;
    CGFloat bottomOffset = 15.0;

    if(self.isShowing) {// move label above the bottom bar
        Y_offset = bottomOffset + self.barHeight;
    }
    else {
        Y_offset = bottomOffset;
    }

    CGSize size = [self.subtitleLabel sizeThatFits:CGSizeMake(self.bounds.size.width - 40.0, CGFLOAT_MAX)];
    self.subtitleLabel.bounds = ({
                                     CGRect bounds = self.subtitleLabel.bounds;
                                     bounds.size = size;
                                     bounds;
                                 });

    self.subtitleLabel.center = CGPointMake(CGRectGetWidth(self.bounds) / 2.0, CGRectGetHeight(self.bounds) - (CGRectGetHeight(self.subtitleLabel.bounds) / 2.0) - Y_offset);

    if([self.subtitleLabel.text length] > 0) {
        self.subtitleLabel.hidden = NO;
    }
    else {
        self.subtitleLabel.hidden = YES;
    }

    [self bringSubviewToFront:self.bottomBar];
}

- (void)initializeSubtitleWithTimer {
	// Start timer

    if(!self.subtitleTimer.isValid) {
        self.subtitleTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                              target:self
                              selector:@selector(searchAndDisplaySubtitle)
                              userInfo:nil
                              repeats:YES];
        [self.subtitleTimer fire];
    }

	// Add label
    if(!self.subtitleLabel) {
        self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.bounds) - 30.0, self.frame.size.height)];
        self.subtitleLabel.center = CGPointMake(CGRectGetWidth(self.bounds) / 2.0, CGRectGetHeight(self.bounds) - (CGRectGetHeight(self.subtitleLabel.bounds) / 2.0) - 15.0);
        self.subtitleLabel.backgroundColor = [UIColor colorWithRed:31.0 / 255.0 green:33.0 / 255.0 blue:36.0 / 255.0 alpha:0.4];
        self.subtitleLabel.textColor = [UIColor whiteColor];
        self.subtitleLabel.numberOfLines = 0;
        self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
        self.subtitleLabel.layer.shouldRasterize = YES;
        self.subtitleLabel.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        self.subtitleLabel.layer.cornerRadius = 5;
        [self addSubview:self.subtitleLabel];
    }

    CGFloat fontSize = 0.0;

    if(self.style == CLVideoPlayerControlsStyleFullscreen || (self.style == CLVideoPlayerControlsStyleDefault && self.moviePlayer.isFullscreen)) {
        fontSize = 18.0;	//MOB-1146
    }
    else if(self.style == CLVideoPlayerControlsStyleEmbedded || (self.style == CLVideoPlayerControlsStyleDefault && !self.moviePlayer.isFullscreen)) {
        fontSize = 12.0;
    }

    self.subtitleLabel.font = [UIFont fontWithName:@"OpenSans" size:fontSize];
}

- (void)updateComponentsOriginOnOrientation {
    self.subtitleLabel.hidden = YES;

    CGFloat fontSize = 0.0;

    if(self.style == CLVideoPlayerControlsStyleFullscreen || (self.style == CLVideoPlayerControlsStyleDefault && self.moviePlayer.isFullscreen)) {
        fontSize = 18.0;	//MOB-1146
    }
    else if(self.style == CLVideoPlayerControlsStyleEmbedded || (self.style == CLVideoPlayerControlsStyleDefault && !self.moviePlayer.isFullscreen)) {
        fontSize = 12.0;
    }

    self.subtitleLabel.font = [UIFont fontWithName:@"OpenSans" size:fontSize];

	// Label position
    [self setSubtitleLabelFrame];

	// UnHidden label
    self.subtitleLabel.hidden = NO;

    if([self.subtitleLabel.text length] > 0) {
        self.subtitleLabel.hidden = NO;
    }
    else {
        self.subtitleLabel.hidden = YES;
    }
}

#pragma mark - CC Notifications

- (void)orientationDidChange:(NSNotification*)notification {
}

#pragma mark - Others

- (void)setSubtitlesParts:(NSMutableDictionary*)subtitlesParts {
    objc_setAssociatedObject(self, @"subtitlesParts", subtitlesParts, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary*)subtitlesParts {
    return objc_getAssociatedObject(self, @"subtitlesParts");
}

- (void)setSubtitleTimer:(NSTimer*)timer {
    objc_setAssociatedObject(self, @"timer", timer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimer*)subtitleTimer {
    return objc_getAssociatedObject(self, @"timer");
}

- (void)setSubtitleLabel:(UILabel*)subtitleLabel {
    objc_setAssociatedObject(self, @"subtitleLabel", subtitleLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UILabel*)subtitleLabel {
    return objc_getAssociatedObject(self, @"subtitleLabel");
}

- (void)setPlayerPlaybackRate:(float)playbackRate {
    self.playbackRate = playbackRate;
}

#pragma mark - Get Video Selected CC Data

- (void)getVideoTranscripts:(NSNotification*)notif {
    NSDictionary* dict = notif.userInfo;

    self.objTranscript = [dict objectForKey:KEY_TRANSCRIPT];

    [self setPersistedLanguage];

    [self.table_Options reloadData];
}

- (void)addCCTableValues {
    self.arr_Values = [[NSMutableArray alloc] init];

    if(self.objTranscript.ChineseURLFilePath) {
        [self.arr_Values addObject:@"Chinese"];
    }

    if(self.objTranscript.EnglishURLFilePath) {
        [self.arr_Values addObject:@"English"];
    }

    if(self.objTranscript.GermanURLFilePath) {
        [self.arr_Values addObject:@"German"];
    }

    if(self.objTranscript.PortugueseURLFilePath) {
        [self.arr_Values addObject:@"Portuguese"];
    }

    if(self.objTranscript.SpanishURLFilePath) {
        [self.arr_Values addObject:@"Spanish"];
    }

    if(self.objTranscript.FrenchURLFilePath) {
        [self.arr_Values addObject:@"French"];
    }
}

// For VideoSpeed and if CC are available more than 3.
- (void)setFullTableSize {
    CGFloat viewInnerWidth = 200.f;
    CGFloat viewInnerHeight = 240.f;
    CGFloat cancelButtonHeight = 44.f;
    CGFloat settingsbtnSize = 24.f;

    self.view_OptionsInner.frame = CGRectMake(self.btnSettings.frame.origin.x - viewInnerWidth + (settingsbtnSize / 2), self.view_OptionsOverlay.frame.size.height - self.barHeight - viewInnerHeight, viewInnerWidth, viewInnerHeight);

    self.table_Values.frame = CGRectMake(0, 0, viewInnerWidth, viewInnerHeight - cancelButtonHeight);

    self.btnCancel.frame = CGRectMake(10, viewInnerHeight - cancelButtonHeight, viewInnerWidth - 20, cancelButtonHeight);
}

// MOB - 599
- (void)changeCCPopUpSize {
    NSInteger count = [self.arr_Values count];

    if(count == 0) {
        return;
    }

    if(self.selectedCCOption == 1) {
        [self setFullTableSize];
        return;
    }

    if(count > 3) {
        [self setFullTableSize];
    }
    else {
        CGFloat Height = (count * 44) + 44 + self.btnCancel.frame.size.height;
        CGFloat Y_Value = self.frame.size.height - self.barHeight - Height;

        self.view_OptionsInner.frame = CGRectMake(self.view_OptionsInner.frame.origin.x, Y_Value, self.view_OptionsInner.frame.size.width, Height);
        self.table_Values.frame = CGRectMake(0, 0, self.view_OptionsInner.frame.size.width, Height - self.btnCancel.frame.size.height);
        self.btnCancel.frame = CGRectMake(self.btnCancel.frame.origin.x, Height - self.btnCancel.frame.size.height, self.btnCancel.frame.size.width, self.btnCancel.frame.size.height);
    }
}

- (void)setPersistedLanguage {
    [self addCCTableValues];
    NSString* strLanguage = [OEXInterface getCCSelectedLanguage];

    if(!strLanguage || [strLanguage isEqualToString:@""]) {
        return;
    }

    for(int i = 0; i < [self.arr_Values count]; i++) {
        if([strLanguage isEqualToString: [self.arr_Values objectAtIndex:i]]) {
            self.selectedCCOption = 0;
            _dataInterface.selectedCCIndex = i;
            break;
        }
        if(i == [self.arr_Values count] - 1) {
            strLanguage = @"";
            return;
        }
    }

    if([strLanguage isEqualToString:@"Chinese"]) {
        [self activateSubTitles:self.objTranscript.ChineseURLFilePath WithFileDownloadURL:self.objTranscript.ChineseDownloadURLString];
    }
    else if([strLanguage isEqualToString:@"English"]) {
        [self activateSubTitles:self.objTranscript.EnglishURLFilePath WithFileDownloadURL:self.objTranscript.EnglishDownloadURLString];
    }
    else if([strLanguage isEqualToString:@"German"]) {
        [self activateSubTitles:self.objTranscript.GermanURLFilePath WithFileDownloadURL:self.objTranscript.GermanDownloadURLString];
    }
    else if([strLanguage isEqualToString:@"Portuguese"]) {
        [self activateSubTitles:self.objTranscript.PortugueseURLFilePath WithFileDownloadURL:self.objTranscript.PortugueseDownloadURLString];
    }
    else if([strLanguage isEqualToString:@"Spanish"]) {
        [self activateSubTitles:self.objTranscript.SpanishURLFilePath WithFileDownloadURL:self.objTranscript.SpanishDownloadURLString];
    }
    else if([strLanguage isEqualToString:@"French"]) {
        [self activateSubTitles:self.objTranscript.FrenchURLFilePath WithFileDownloadURL:self.objTranscript.FrenchDownloadURLString];
    }
}

# pragma  mark PLAYER CONTROLS METHODS
# pragma mark - Construct/Destruct

- (id)initWithMoviePlayer:(CLVideoPlayer*)moviePlayer style:(CLVideoPlayerControlsStyle)style {
    self = [super init];
    if(self) {
        self.seeking = NO;
	// Initialize the interface
        self.dataInterface = [OEXInterface sharedInterface];
        self.backgroundColor = [UIColor clearColor];
        _moviePlayer = moviePlayer;
        _style = style;
        _showing = NO;
        _fadeDelay = 5.0;
        _timeRemainingDecrements = NO;
        _barColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
	//in fullscreen mode, move controls away from top status bar and bottom screen bezel. I think the iOS7 control center gestures interfere with the uibutton touch events. this will alleviate that a little (correct me if I'm wrong and/or adjust if necessary).
        _barHeight = [UIDevice iOSVersion] >= 7.0 ? 50.f : 48.f;
        _seekRate = 3.f;
        _state = CLVideoPlayerControlsStateIdle;
        _hideNext = NO;
        _hidePrevious = NO;
        _stateBeforeSeek = MPMoviePlaybackStatePlaying;
        _playbackRate = 1.0;	//Defalt value on intialize
        self.arr_Values = [[NSMutableArray alloc] init];
        [self setup];
        [self addNotifications];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_durationTimer invalidate];
    [_bufferedTimer invalidate];
    if([self.subtitleTimer isValid]) {
        [self.subtitleTimer invalidate];
    }
    [self nilDelegates];
    _table_Options.delegate = nil;
    _table_Values.delegate = nil;
    _durationSlider = nil;

    ELog(@"Dealloc get called ClVideoPlayerControls");
}

-(void)resetControls {
    [self removeObservers];
    [self nilDelegates];
    _timeRemainingLabel = nil;
    _timeElapsedLabel = nil;
    _table_Values = nil;
    _table_Options = nil;
}

-(void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if([_durationTimer isValid]) {
        [_durationTimer invalidate];
    }

    if([_durationTimer isValid]) {
        [_bufferedTimer invalidate];
    }

    [self removeFromSuperview];
}

-(void)setup {
    if(self.style == CLVideoPlayerControlsStyleNone) {
        return;
    }

	//top bar
    _topBar = [[CLMoviePlayerControlsBar alloc] init];
    _topBar.color = _barColor;
    _topBar.alpha = 0.f;
    [self addSubview:_topBar];

	//bottom bar
    _bottomBar = [[CLMoviePlayerControlsBar alloc] init];
    _bottomBar.color = _barColor;
    _bottomBar.alpha = 0.f;
    [self addSubview:_bottomBar];

    _videoTitleLabel = [[UILabel alloc] init];
    _videoTitleLabel.backgroundColor = [UIColor clearColor];
    _videoTitleLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:16.f];
    _videoTitleLabel.textColor = [UIColor whiteColor];
    _videoTitleLabel.textAlignment = NSTextAlignmentLeft;
    _videoTitleLabel.text = @"Untitled";
    if(_moviePlayer.videoTitle == nil || [_videoTitleLabel.text isEqualToString:@""]) {
        _videoTitleLabel.text = @"Untitled";
        _moviePlayer.videoTitle = @"Untitled";
    }
    else {
        _videoTitleLabel.text = self.moviePlayer.videoTitle;
    }

    _videoTitleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    _videoTitleLabel.layer.shadowRadius = 1.f;
    _videoTitleLabel.layer.shadowOffset = CGSizeMake(1.f, 1.f);
    _videoTitleLabel.layer.shadowOpacity = 0.8f;

    [_topBar addSubview:_videoTitleLabel];

    _durationSlider = [[OEXCustomSlider alloc] init];
    _durationSlider.value = 0.f;
    _durationSlider.secondaryProgress = 0.f;
    _durationSlider.continuous = YES;

    [_durationSlider setThumbImage:[UIImage imageNamed:@"ic_seek_thumb"] forState:UIControlStateNormal];
    [_durationSlider setMinimumTrackImage:[UIImage imageNamed:@"ic_progressbar.png"] forState:UIControlStateNormal];
    [_durationSlider setSecondaryTrackColor:[UIColor colorWithRed:(float)76 / 255 green:(float)135 / 255 blue:(float)130 / 255 alpha:0.9]];
    [_durationSlider addTarget:self action:@selector(durationSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [_durationSlider addTarget:self action:@selector(durationSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
    [_durationSlider addTarget:self action:@selector(durationSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside];
    [_durationSlider addTarget:self action:@selector(durationSliderTouchEnded:) forControlEvents:UIControlEventTouchUpOutside];

    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideOptionsAndValues)];
    [_durationSlider addGestureRecognizer:tap];

    _timeRemainingLabel = [[UILabel alloc] init];
    _timeRemainingLabel.backgroundColor = [UIColor clearColor];
    _timeRemainingLabel.textColor = [UIColor lightTextColor];
    _timeRemainingLabel.textAlignment = NSTextAlignmentCenter;
    _timeRemainingLabel.text = @"0:00/0:00";
    _timeRemainingLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    _timeRemainingLabel.layer.shadowRadius = 1.f;
    _timeRemainingLabel.layer.shadowOffset = CGSizeMake(1.f, 1.f);
    _timeRemainingLabel.layer.shadowOpacity = 0.8f;
    _timeRemainingLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:12.f];

    self.btnPrevious = [[CLButton alloc] init];
    [self.btnPrevious setImage:[UIImage imageNamed:@"ic_previous.png"] forState:UIControlStateNormal];
    [self.btnPrevious setImage:[UIImage imageNamed:@"ic_previous_press.png"] forState:UIControlStateHighlighted];
    [self.btnPrevious addTarget:self action:@selector(previousBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.btnPrevious.delegate = self;

    self.btnNext = [[CLButton alloc] init];
    [self.btnNext setImage:[UIImage imageNamed:@"ic_next.png"] forState:UIControlStateNormal];
    [self.btnNext setImage:[UIImage imageNamed:@"ic_next_press.png"] forState:UIControlStateHighlighted];
    [self.btnNext addTarget:self action:@selector(nextBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.btnNext.delegate = self;

    if(_style == CLVideoPlayerControlsStyleFullscreen || (_style == CLVideoPlayerControlsStyleDefault && _moviePlayer.isFullscreen)) {
        [_bottomBar addSubview:_durationSlider];
        [_bottomBar addSubview:_timeRemainingLabel];
        [self addSubview:self.btnPrevious];
        [self addSubview:self.btnNext];
    }
    else if(_style == CLVideoPlayerControlsStyleEmbedded || (_style == CLVideoPlayerControlsStyleDefault && !_moviePlayer.isFullscreen)) {
        [_bottomBar addSubview:_durationSlider];
        [_bottomBar addSubview:_timeRemainingLabel];
    }

	///Rewind  button
    _rewindButton = [[CLButton alloc] init];
    [_rewindButton setImage:[UIImage imageNamed:@"rewind.png"] forState:UIControlStateNormal];
    [_rewindButton setImage:[UIImage imageNamed:@"rewind.png"] forState:UIControlStateSelected];
    _rewindButton.delegate = self;
    [_rewindButton addTarget:self action:@selector(seekBackwardPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomBar addSubview:_rewindButton];

	//static stuff
    _playPauseButton = [[CLButton alloc] init];
    if(_style == CLVideoPlayerControlsStyleFullscreen || (_style == CLVideoPlayerControlsStyleDefault && _moviePlayer.isFullscreen)) {
        [_playPauseButton setImage:[UIImage imageNamed:@"ic_pause.png"] forState:UIControlStateNormal];
        [_playPauseButton setImage:[UIImage imageNamed:@"ic_play.png"] forState:UIControlStateSelected];
    }
    else if(_style == CLVideoPlayerControlsStyleEmbedded || (_style == CLVideoPlayerControlsStyleDefault && !_moviePlayer.isFullscreen)) {
        [_playPauseButton setImage:[UIImage imageNamed:@"ic_potrait_pause.png"] forState:UIControlStateNormal];
        [_playPauseButton setImage:[UIImage imageNamed:@"ic_potrait_play.png"] forState:UIControlStateSelected];
    }

    [_playPauseButton setSelected:_moviePlayer.playbackState == MPMoviePlaybackStatePlaying ? NO : YES];
    [_playPauseButton addTarget:self action:@selector(playPausePressed:) forControlEvents:UIControlEventTouchUpInside];
    _playPauseButton.delegate = self;
    [self addSubview:_playPauseButton];

    self.view_OptionsOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    self.view_OptionsOverlay.backgroundColor = [UIColor blackColor];
    self.view_OptionsOverlay.alpha = 0.5f;
    [self addSubview:self.view_OptionsOverlay];

    self.view_OptionsInner = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    self.view_OptionsInner.backgroundColor = GREY_COLOR;
    self.view_OptionsInner.layer.cornerRadius = 10;
    self.view_OptionsInner.layer.shadowColor = [UIColor blackColor].CGColor;
    self.view_OptionsInner.layer.shadowRadius = 1.f;
    self.view_OptionsInner.layer.shadowOffset = CGSizeMake(1.f, 1.f);
    self.view_OptionsInner.layer.shadowOpacity = 0.8f;
    self.view_OptionsInner.layer.masksToBounds = YES;
    [self addSubview:self.view_OptionsInner];

    self.table_Options = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 0, 0) style:UITableViewStylePlain];
    self.table_Options.delegate = self;
    self.table_Options.dataSource = self;
    self.table_Options.layer.cornerRadius = 10;
    self.table_Options.layer.shadowColor = [UIColor blackColor].CGColor;
    self.table_Options.layer.shadowRadius = 1.f;
    self.table_Options.layer.shadowOffset = CGSizeMake(1.f, 1.f);
    self.table_Options.layer.shadowOpacity = 0.8f;
    self.table_Options.separatorInset = UIEdgeInsetsZero;

#ifdef __IPHONE_8_0
    if(IS_IOS8) {
        [self.table_Options setLayoutMargins:UIEdgeInsetsZero];
    }
#endif

    [self addSubview:self.table_Options];
    self.table_Values = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 0, 0) style:UITableViewStylePlain];
    self.table_Values.delegate = self;
    self.table_Values.dataSource = self;
    self.table_Values.separatorInset = UIEdgeInsetsZero;
#ifdef __IPHONE_8_0
    if(IS_IOS8) {
        [self.table_Values setLayoutMargins:UIEdgeInsetsZero];
    }
#endif
    [self.view_OptionsInner addSubview:self.table_Values];

    [self.table_Options registerNib:[UINib nibWithNibName:@"OEXClosedCaptionTableViewCell" bundle:nil] forCellReuseIdentifier:@"CustomCell"];

    [self.table_Values registerNib:[UINib nibWithNibName:@"OEXClosedCaptionTableViewCell" bundle:nil] forCellReuseIdentifier:@"CustomCell"];

    self.btnCancel = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnCancel.titleLabel setFont:[UIFont fontWithName:@"OpenSans" size:12.0]];
    [self.btnCancel setTitle:@"None" forState:UIControlStateNormal];
    [self.btnCancel setTitle:@"None" forState:UIControlStateSelected];
    self.btnCancel.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [self.btnCancel setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.btnCancel addTarget:self action:@selector(cancelBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view_OptionsInner addSubview:self.btnCancel];

    _btnSettings = [[CLButton alloc] init];
    [_btnSettings.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:12.0]];
    [_btnSettings setImage:[UIImage imageNamed:@"ic_settings.png"] forState:UIControlStateNormal];
    [_btnSettings setImage:[UIImage imageNamed:@"ic_settings_press.png"] forState:UIControlStateHighlighted];
    [_btnSettings setImage:[UIImage imageNamed:@"ic_settings_press.png"] forState:UIControlStateSelected];
    [_btnSettings setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _btnSettings.delegate = self;
    [_btnSettings addTarget:self action:@selector(settingsBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomBar addSubview:_btnSettings];

    self.btnLMS = [[CLButton alloc] init];
    [self.btnLMS setImage:[UIImage imageNamed:@"ic_lms.png"] forState:UIControlStateNormal];
    [self.btnLMS addTarget:self action:@selector(LMSBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.btnLMS.delegate = self;
    [_topBar addSubview:self.btnLMS];

    _fullscreenButton = [[CLButton alloc] init];
    [_fullscreenButton setImage:[UIImage imageNamed:@"movieFullscreen.png"] forState:UIControlStateNormal];
    [_fullscreenButton addTarget:self action:@selector(fullscreenPressed:) forControlEvents:UIControlEventTouchUpInside];
    _fullscreenButton.delegate = self;
    [_bottomBar addSubview:_fullscreenButton];

    _activityBackgroundView = [[UIView alloc] init];
    [_activityBackgroundView setBackgroundColor:[UIColor blackColor]];
    _activityBackgroundView.alpha = 0.f;

    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.alpha = 0.f;
    _activityIndicator.hidesWhenStopped = YES;

	// SWIPE GESTURE

    if(_style == CLVideoPlayerControlsStyleFullscreen || (_style == CLVideoPlayerControlsStyleDefault && _moviePlayer.isFullscreen)) {
        if(self.video.summary.videoID) {
            [[OEXAnalytics sharedAnalytics] trackVideoOrientation: self.video.summary.videoID
             CourseID: self.video.course_id
             CurrentTime: [self getMoviePlayerCurrentTime]
             Mode: YES
             UnitURL: self.video.summary.unitURL];
        }

        self.leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(nextBtnClicked:)];
        self.leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
        [self.moviePlayer.view addGestureRecognizer:self.leftSwipeGestureRecognizer];

        self.rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(previousBtnClicked:)];
        self.rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
        [self.moviePlayer.view addGestureRecognizer:self.rightSwipeGestureRecognizer];
    }
    else if(_style == CLVideoPlayerControlsStyleEmbedded || (_style == CLVideoPlayerControlsStyleDefault && !_moviePlayer.isFullscreen)) {
        if(self.video.summary.videoID) {
            [[OEXAnalytics sharedAnalytics] trackVideoOrientation: self.video.summary.videoID
             CourseID: self.video.course_id
             CurrentTime: [self getMoviePlayerCurrentTime]
             Mode: NO
             UnitURL: self.video.summary.unitURL];
        }

        [self.moviePlayer.view removeGestureRecognizer:self.rightSwipeGestureRecognizer];
        [self.moviePlayer.view removeGestureRecognizer:self.leftSwipeGestureRecognizer];
    }

    self.arr_SettingOptions = [[NSMutableArray alloc] initWithObjects:@"Closed Captions", @"Video Speed", nil];

	// hide tables initially
    [self didHideTables:YES];
    [self setPlayerControlAccessibilityID];
}

- (void)resetViews {
    [self stopDurationTimer];
    [self nilDelegates];
    [_activityBackgroundView removeFromSuperview];
    [_activityIndicator removeFromSuperview];
    [_playPauseButton removeFromSuperview];
    [_btnNext removeFromSuperview];
    [_btnPrevious removeFromSuperview];
    [_topBar removeFromSuperview];
    [_bottomBar removeFromSuperview];
    [_table_Options removeFromSuperview];
    [_table_Values removeFromSuperview];
}

- (void)nilDelegates {
    _playPauseButton.delegate = nil;
    _fullscreenButton.delegate = nil;
    _seekForwardButton.delegate = nil;
    _rewindButton.delegate = nil;
    _btnSettings.delegate = nil;
    _btnPrevious.delegate = nil;
    _btnNext.delegate = nil;
    _btnLMS.delegate = nil;
    _scaleButton.delegate = nil;
    _table_Options.delegate = nil;
    _table_Values.delegate = nil;
}

-(void)hideOptionsAndValues {
    self.btnSettings.selected = NO;
    [_btnSettings setImage:[UIImage imageNamed:@"ic_settings.png"] forState:UIControlStateNormal];
    self.view_OptionsOverlay.hidden = YES;
    self.table_Options.hidden = YES;
    self.view_OptionsInner.hidden = YES;
    self.table_Values.hidden = YES;
}

# pragma mark - Setters

-(void)setStyle:(CLVideoPlayerControlsStyle)style {
    if(_style != style) {
        BOOL flag = _style == CLVideoPlayerControlsStyleDefault;
        __weak id weakSelf = self;
        [self hideControls:^{
             [self resetViews];
             _style = style;
             [weakSelf setup];
             if(_style != CLVideoPlayerControlsStyleNone) {
                 double delayInSeconds = 0.2;
                 dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                 dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                    [weakSelf setDurationSliderMaxMinValues];
                                    [weakSelf monitorMoviePlayback];	//resume values
                                    [weakSelf startDurationTimer];
                                    [weakSelf showControls:^{
                                         if(flag) {
                                             _style = CLVideoPlayerControlsStyleDefault;
                                         }
                                     }];
                                });
             }
             else {
                 if(flag) {
			//put style back to default
                     _style = CLVideoPlayerControlsStyleDefault;
                 }
             }
         }];
    }
}

- (void)setState:(CLVideoPlayerControlsState)state {
    if(_state != state) {
        _state = state;

        switch(state) {
            case CLVideoPlayerControlsStateLoading :
                [self showLoadingIndicators];
                break;
            case CLVideoPlayerControlsStateReady:
		//Commented hide login indicators
                [self hideLoadingIndicators];
                break;
            case CLVideoPlayerControlsStateIdle:
            default:
                break;
        }
    }
}

- (void)setBarColor:(UIColor*)barColor {
    if(_barColor != barColor) {
        _barColor = barColor;
        [self.topBar setColor:barColor];
        [self.bottomBar setColor:barColor];
    }
}

#pragma BUTTTON ACTION METHOD

- (void)hideUnhidePreviousNextButton:(NSNotification*)notif {
	// Disable the subtitle when any new video is played.
	// This is played from the portrait mode.

    self.subtitlesParts = nil;
    [self hideSubtitles];

    NSDictionary* dict = notif.userInfo;

	// Check for previous button
    if([[dict objectForKey:KEY_DISABLE_NEXT] isEqualToString:@"YES"]) {
        self.hideNext = YES;
    }
    else if([[dict objectForKey:KEY_DISABLE_NEXT] isEqualToString:@"NO"]) {
        self.hideNext = NO;
    }

	// Check for previous button
    if([[dict objectForKey:KEY_DISABLE_PREVIOUS] isEqualToString:@"YES"]) {
        self.hidePrevious = YES;
    }
    else if([[dict objectForKey:KEY_DISABLE_PREVIOUS] isEqualToString:@"NO"]) {
        self.hidePrevious = NO;
    }
    [self didHidePrevNext];
}

- (void)didHidePrevNext {
    if(!self.leftSwipeGestureRecognizer) {
        self.leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(nextBtnClicked:)];
        self.leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    }

    if(!self.rightSwipeGestureRecognizer) {
        self.rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(previousBtnClicked:)];
        self.rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    }

	// Hide unhide the next button
    if(self.hideNext) {
        self.btnNext.hidden = YES;
        self.btnNext.enabled = NO;
        [self.moviePlayer.view removeGestureRecognizer:self.leftSwipeGestureRecognizer];
    }
    else {
        self.btnNext.hidden = NO;
        self.btnNext.enabled = YES;
        [self.moviePlayer.view addGestureRecognizer:self.leftSwipeGestureRecognizer];
    }

	// Hide unhide the previous button
    if(self.hidePrevious) {
        self.btnPrevious.hidden = YES;
        self.btnPrevious.enabled = NO;
        [self.moviePlayer.view removeGestureRecognizer:self.rightSwipeGestureRecognizer];
    }
    else {
        self.btnPrevious.hidden = NO;
        self.btnPrevious.enabled = YES;
        [self.moviePlayer.view addGestureRecognizer:self.rightSwipeGestureRecognizer];
    }
}

- (void)settingsBtnClicked:(id)sender {
    if([self.btnSettings isSelected]) {
        self.btnSettings.selected = NO;
        [_btnSettings setImage:[UIImage imageNamed:@"ic_settings.png"] forState:UIControlStateNormal];
    }
    else {
        self.btnSettings.selected = YES;
        [_btnSettings setImage:[UIImage imageNamed:@"ic_settings_press.png"] forState:UIControlStateNormal];
    }

	// Hide unhide the option tableview
    self.view_OptionsOverlay.hidden = NO;
    self.table_Options.hidden = NO;
    self.view_OptionsInner.hidden = YES;
    self.table_Values.hidden = YES;

    [self bringSubviewToFront:self.table_Options];
}

-(void)analyticsShowTranscript {
    [[OEXAnalytics sharedAnalytics] trackShowTranscript:self.video.summary.videoID
     CurrentTime:[self getMoviePlayerCurrentTime]
     CourseID:self.video.course_id
     UnitURL:self.video.summary.unitURL];
}

#pragma CC methods

- (void)cancelBtnClicked:(id)sender {
    [self hideControls:nil];
	// remove contents of the dictionary loaded
	// to avoid the previously selected data showing up
	// as soon the user switches to another language after OFF.
    if(_selectedCCOption == 0) {// Remove subtitle only for CC option and not for speed control option.
	// Set the language to blank
        [OEXInterface setCCSelectedLanguage:@""];
	// Analytics HIDE TRANSCRIPT
        if(self.video.summary.videoID) {
            [[OEXAnalytics sharedAnalytics] trackHideTranscript:self.video.summary.videoID
             CurrentTime:[self getMoviePlayerCurrentTime]
             CourseID:self.video.course_id
             UnitURL:self.video.summary.unitURL];
        }
        _dataInterface.selectedCCIndex = -1;
        self.subtitlesParts = nil;
        [self hideSubtitles];
    }
    else if(_selectedCCOption == 1) {
        _dataInterface.selectedVideoSpeedIndex = -1;
        _playbackRate = 1.0;
        [self.moviePlayer setCurrentPlaybackRate:_playbackRate];
    }
}

- (void)LMSBtnClicked:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.video.summary.unitURL]];
}

# pragma mark - UIControl/Touch Events

- (void)previousBtnClicked:(id)sender {
    if([sender isKindOfClass:[UISwipeGestureRecognizer class]] && !self.moviePlayer.isFullscreen) {
        return;
    }
    [self setDefaultPlaybackSpeed];
    self.subtitlesParts = nil;
    _dataInterface.selectedCCIndex = -1;
    _dataInterface.selectedVideoSpeedIndex = -1;
    [self hideSubtitles];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_PREVIOUS_VIDEO object:self userInfo:nil];
}

- (void)nextBtnClicked:(id)sender {
    if([sender isKindOfClass:[UISwipeGestureRecognizer class]] && !self.moviePlayer.isFullscreen) {
        return;
    }

    [self setDefaultPlaybackSpeed];

    self.subtitlesParts = nil;
    _dataInterface.selectedCCIndex = -1;
    _dataInterface.selectedVideoSpeedIndex = -1;
    [self hideSubtitles];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NEXT_VIDEO object:self userInfo:nil];
}

- (void)durationSliderTouchBegan:(UISlider*)slider {
    [self hideOptionsAndValues];

	//Fix semantics - MOB -1232
    self.startTime = [self getMoviePlayerCurrentTime];
    NSLog(@"self.startTime : %f", self.startTime);

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls:) object:nil];
	// Pause player
    self.seeking = YES;
    [self.moviePlayer pause];
	//[self stopDurationTimer];
}

- (void)durationSliderTouchEnded:(UISlider*)slider {
    [self hideOptionsAndValues];

    self.seeking = NO;
    [self.moviePlayer setCurrentPlaybackTime:floor(slider.value)];

	//Fix semantics - MOB -1232
    self.stopTime = [self getMoviePlayerCurrentTime];
    NSLog(@"self.stopTime : %f", self.stopTime);

    if(self.video.summary.videoID) {
        [[OEXAnalytics sharedAnalytics] trackVideoSeekRewind:self.video.summary.videoID
         RequestedDuration:self.stopTime - self.startTime
         OldTime:self.startTime
         NewTime:self.stopTime
         CourseID:self.video.course_id
         UnitURL:self.video.summary.unitURL
         SkipType:@"slide"];
    }

    if(self.stateBeforeSeek == MPMoviePlaybackStatePlaying && self.moviePlayer
       .loadState != MPMovieLoadStateStalled) {
        [self.moviePlayer setCurrentPlaybackRate:_playbackRate];
        [self.moviePlayer play];
    }

    [self performSelector:@selector(hideControls:) withObject:nil afterDelay:self.fadeDelay];
}

- (void)durationSliderValueChanged:(UISlider*)slider {
    [self hideOptionsAndValues];

    NSTimeInterval currentTime = (NSTimeInterval)slider.value;
    NSTimeInterval totalTime = (NSTimeInterval)self.moviePlayer.duration;
    [self setTimeLabelValues:currentTime totalTime:totalTime];
}

- (void)buttonTouchedDown:(UIButton*)button {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls:) object:nil];
}

- (void)buttonTouchedUpOutside:(UIButton*)button {
    [self performSelector:@selector(hideControls:) withObject:nil afterDelay:self.fadeDelay];
}

- (void)buttonTouchCancelled:(UIButton*)button {
    [self performSelector:@selector(hideControls:) withObject:nil afterDelay:self.fadeDelay];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if(![keyPath isEqualToString:@"layer.sublayers"]) {
        return;
    }
    UIWindow* keyWindow = [[UIApplication sharedApplication] keyWindow];
    if(!keyWindow) {
        keyWindow = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
    }
    if(keyWindow.layer.sublayers.count == windowSubviews) {
        [keyWindow removeObserver:self forKeyPath:@"layer.sublayers"];
        [self performSelector:@selector(hideControls:) withObject:nil afterDelay:self.fadeDelay];
    }
}

- (void)playPausePressed:(UIButton*)button {
    if(self.moviePlayer.playbackState == MPMoviePlaybackStatePlaying) {
        self.stateBeforeSeek = MPMoviePlaybackStatePaused;
        [self.moviePlayer pause];
        [_dataInterface sendAnalyticsEvents:OEXVideoStatePause withCurrentTime:[self getMoviePlayerCurrentTime] forVideo:self.video];
    }
    else {
        self.stateBeforeSeek = MPMoviePlaybackStatePlaying;
        [self.moviePlayer play];
        [_dataInterface sendAnalyticsEvents:OEXVideoStatePlay withCurrentTime:[self getMoviePlayerCurrentTime] forVideo:self.video];
    }

    [self performSelector:@selector(hideControls:) withObject:nil afterDelay:self.fadeDelay];
}

- (void)fullscreenPressed:(UIButton*)button {
    if(self.style == CLVideoPlayerControlsStyleDefault) {
        self.style = self.moviePlayer.isFullscreen ? CLVideoPlayerControlsStyleEmbedded : CLVideoPlayerControlsStyleFullscreen;
    }
    [self.moviePlayer setFullscreen:!self.moviePlayer.isFullscreen animated:YES forceRotate:YES];

	// For the self.subtitleLabel font.
    [self updateComponentsOriginOnOrientation];

    [self performSelector:@selector(hideControls:) withObject:nil afterDelay:self.fadeDelay];
}

- (void)seekBackwardPressed:(UIButton*)button {
    [self hideOptionsAndValues];

    NSTimeInterval OldTime = [self getMoviePlayerCurrentTime];
    NSTimeInterval currentTime = 0;

    if(self.moviePlayer.currentPlaybackTime > CLVideoSkipBackwardsDuration) {
        currentTime = self.moviePlayer.currentPlaybackTime - CLVideoSkipBackwardsDuration;
    }
    else {
        currentTime = 0;
    }

    if(self.video.summary.videoID) {
        [[OEXAnalytics sharedAnalytics] trackVideoSeekRewind:self.video.summary.videoID
         RequestedDuration:-CLVideoSkipBackwardsDuration
         OldTime:OldTime
         NewTime:currentTime
         CourseID:self.video.course_id
         UnitURL:self.video.summary.unitURL
         SkipType:@"skip"];
    }

    ELog(@"Current platback time %d and  after 30sec rewind %d ", self.moviePlayer.currentPlaybackTime, currentTime);
    [self.moviePlayer pause];
	//Dont delete commented code
	////self.durationSlider.value=currentTime;
	// [self setTimeLabelValues:(double)currentTime totalTime:(double)self.moviePlayer.duration];

    [self.moviePlayer setCurrentPlaybackTime:floor(currentTime)];
    self.durationSlider.value = currentTime;
    [self setTimeLabelValues:(double)currentTime totalTime:(double)self.moviePlayer.duration];

    if(self.stateBeforeSeek == MPMoviePlaybackStatePlaying && self.moviePlayer
       .loadState != MPMovieLoadStateStalled) {
        [self.moviePlayer setCurrentPlaybackRate:_playbackRate];
        [self.moviePlayer play];
    }

    [self performSelector:@selector(hideControls:) withObject:nil afterDelay:self.fadeDelay];
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    if(self.style == CLVideoPlayerControlsStyleNone) {
        return;
    }
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    if(self.style == CLVideoPlayerControlsStyleNone || self.state == CLVideoPlayerControlsStateLoading) {
        return;
    }

    self.isShowing ?[self hideControls:nil] :[self showControls:nil];
}

# pragma mark - Internal Methods
# pragma mark - Internal Methods

- (void)startDurationTimer {
    [self stopDurationTimer];
    self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(monitorMoviePlayback) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.durationTimer forMode:NSDefaultRunLoopMode];
}
- (void)stopDurationTimer {
    [self.durationTimer invalidate];
}
- (void)startBufferedTimer {
    [self stopBufferedTimer];
    self.bufferedTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(monitorBufferedMovie) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.bufferedTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopBufferedTimer {
    if([self.bufferedTimer isValid]) {
        [self.bufferedTimer invalidate];
    }
}

- (void)showControls:(void (^)(void))completion {
	// if (!self.isShowing && !self.loadingContentUrl) {
    if(!self.isShowing) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls:) object:nil];
        if(self.style == CLVideoPlayerControlsStyleFullscreen || (self.style == CLVideoPlayerControlsStyleDefault && self.moviePlayer.isFullscreen)) {
        }
        [self.topBar setNeedsDisplay];
        [self.bottomBar setNeedsDisplay];
        __weak CLVideoPlayerControls* weakself = self;
        [UIView animateWithDuration:0.3 delay:0.0 options:0 animations:^{
             self.topBar.alpha = 1.f;
             self.playPauseButton.alpha = 1.f;
             self.btnPrevious.alpha = 1.f;
             self.btnNext.alpha = 1.f;
             self.bottomBar.alpha = 1.f;
             self.playPauseButton.userInteractionEnabled = YES;
             [self.topBar setNeedsDisplay];
             [self.bottomBar setNeedsDisplay];
		// MOB - 499
             if(!self.hideNext) {
                 self.btnNext.enabled = YES;
             }

             if(!self.hidePrevious) {
                 self.btnPrevious.enabled = YES;
             }
         } completion:^(BOOL finished) {
             _showing = YES;
             if(completion) {
                 completion();
             }
		//Hide controls only when player is in fullscreen mode
             [weakself performSelector:@selector(hideControls:) withObject:nil afterDelay:weakself.fadeDelay];
         }];
    }
    else {
        if(completion) {
            completion();
        }
    }
}

- (void)hideControls:(void (^)(void))completion {
    if(self.isShowing) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls:) object:nil];
        [UIView animateWithDuration:0.3 delay:0.0 options:0 animations:^{
             if(self.style == CLVideoPlayerControlsStyleFullscreen || (self.style == CLVideoPlayerControlsStyleDefault && self.moviePlayer.isFullscreen)) {
             }
             self.topBar.alpha = 0.f;
             self.bottomBar.alpha = 0.f;
             self.playPauseButton.alpha = 0.f;
             self.btnPrevious.alpha = 0.f;
             self.btnNext.alpha = 0.f;
             self.playPauseButton.userInteractionEnabled = NO;
		// MOB - 499
             self.btnNext.enabled = NO;
             self.btnPrevious.enabled = NO;

		// Hide tables with all the other control fades.
             [self didHideTables:YES];
             self.btnSettings.selected = NO;
             [_btnSettings setImage:[UIImage imageNamed:@"ic_settings.png"] forState:UIControlStateNormal];
         } completion:^(BOOL finished) {
             _showing = NO;
             if(completion) {
                 completion();
             }
         }];
    }
    else {
        if(completion) {
            completion();
        }
    }
}

- (void)showLoadingIndicators {
    [self addSubview:_activityBackgroundView];
    [self addSubview:_activityIndicator];
    [_activityIndicator startAnimating];

    [UIView animateWithDuration:0.2f animations:^{
         _activityBackgroundView.alpha = 1.f;
         _activityIndicator.alpha = 1.f;
     }];
}

- (void)hideLoadingIndicators {
    [UIView animateWithDuration:0.2f delay:0.0 options:0 animations:^{
         self.activityBackgroundView.alpha = 0.0f;
         self.activityIndicator.alpha = 0.f;
     } completion:^(BOOL finished) {
         [self.activityBackgroundView removeFromSuperview];
         [self.activityIndicator removeFromSuperview];
     }];
}

- (void)setDurationSliderMaxMinValues {
    if(_moviePlayer.videoTitle == nil) {
        _videoTitleLabel.text = @"Untitled";
    }
    else {
        _videoTitleLabel.text = self.moviePlayer.videoTitle;
    }

    CGFloat duration = self.moviePlayer.duration;
    self.durationSlider.minimumValue = 0.f;
    self.durationSlider.maximumValue = floor(duration);
}

- (void)setTimeLabelValues:(double)currentTime totalTime:(double)totalTime {
    double minutesElapsed = floor(currentTime / 60.0);
    double secondsElapsed = fmod(currentTime, 60.0);

    if(isnan(minutesElapsed) || minutesElapsed <= 0) {
        minutesElapsed = 0.00;
    }
    if(isnan(secondsElapsed) || secondsElapsed <= 0) {
        secondsElapsed = 0.00;
    }

    self.timeElapsedLabel.text = [NSString stringWithFormat:@"%.0f:%02.0f", minutesElapsed, secondsElapsed];
    NSString* timeeElapsedStr = [NSString stringWithFormat:@"%.0f:%02.0f", minutesElapsed, secondsElapsed];

    double minutesRemaining;
    double secondsRemaining;
    if(self.timeRemainingDecrements) {
        minutesRemaining = floor((totalTime ) / 60.0);
        secondsRemaining = fmod((totalTime ), 60.0);
    }
    else {
        minutesRemaining = floor(totalTime / 60.0);
        secondsRemaining = floor(fmod(totalTime, 60.0));
    }

    if(isnan(minutesRemaining)) {
        minutesRemaining = 0.00;
    }
    if(isnan(secondsRemaining)) {
        secondsRemaining = 0.00;
    }

    self.timeRemainingLabel.text = self.timeRemainingDecrements ?[NSString stringWithFormat:@"%@ / %.0f:%02.0f", timeeElapsedStr, minutesRemaining, secondsRemaining] :[NSString stringWithFormat:@"%@ / %.0f:%02.0f", timeeElapsedStr, minutesRemaining, secondsRemaining];
}

- (void)monitorMoviePlayback {
    if(!self.seeking) {
        double currentTime = (double)self.moviePlayer.currentPlaybackTime;
        double totalTime = (double)self.moviePlayer.duration;
        [self setTimeLabelValues:currentTime totalTime:totalTime];
        self.durationSlider.value = floor(currentTime);
    }
}

-(void)monitorBufferedMovie {
    double secondaryProgress = floor(self.moviePlayer.playableDuration);
    double totalTime = floor(self.moviePlayer.duration);
    float time = secondaryProgress / totalTime;
    if(isnan(time)) {
        if(self.moviePlayer.playbackState != MPMoviePlaybackStatePlaying) {
            [self stopBufferedTimer];
        }
    }
    self.durationSlider.secondaryProgress = time;
}

# pragma mark - Notifications

- (void)addNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackStateDidChange:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieContentURLDidChange:) name:CLVideoPlayerContentURLDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieDurationAvailable:) name:MPMovieDurationAvailableNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieLoadStateDidChange:) name:MPMoviePlayerLoadStateDidChangeNotification object:nil];

// Used For CC

    [[NSNotificationCenter defaultCenter] addObserver:self
     selector:@selector(orientationDidChange:)
     name:UIDeviceOrientationDidChangeNotification
     object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
     selector:@selector(callPortraitSubtitles:)
     name:NOTIFICATION_CC_SELECTED
     object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
     selector:@selector(hideUnhidePreviousNextButton:)
     name:NOTIFICATION_HIDE_PREV_NEXT
     object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
     selector:@selector(getVideoTranscripts:)
     name:NOTIFICATION_TRANSCRIPT
     object:nil];
}

- (void)movieFinished:(NSNotification*)notification {
    __weak CLVideoPlayerControls* weakSelf = self;

    int reason = [[[notification userInfo] valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    if(reason == MPMovieFinishReasonPlaybackEnded) {
        self.playPauseButton.selected = YES;
        [self.durationTimer invalidate];
        [self.bufferedTimer invalidate];
        self.stateBeforeSeek = MPMoviePlaybackStatePaused;

        [self monitorMoviePlayback];
        [self hideControls:nil];
        self.state = CLVideoPlayerControlsStateIdle;
        ELog(@" %s Reason: movie finished playing ", __PRETTY_FUNCTION__ );

	// Fix semantics - MOB 1232
        if(self.video.summary.videoID) {
            [_dataInterface sendAnalyticsEvents:OEXVideoStateStop withCurrentTime:[weakSelf getMoviePlayerCurrentTime] forVideo:self.video];
        }
    }
    else if(reason == MPMovieFinishReasonUserExited) {
        ELog(@"Reason: user hit done button");
    }
    else if(reason == MPMovieFinishReasonPlaybackError) {
        ELog(@"Reason: MPMovieFinishReasonPlaybackError --> CLVideoPlayerControl");
        [self.activityIndicator stopAnimating];
    }
}

- (void)movieLoadStateDidChange:(NSNotification*)note {
    switch(self.moviePlayer.loadState)
    {
        case MPMovieLoadStatePlayable:
            ELog(@"Load state ==> MPMovieLoadStatePlayable");

        case MPMovieLoadStatePlaythroughOK:
            if(self.loadingContentUrl) {
                self.loadingContentUrl = NO;
            }
            if(self.moviePlayer.lastPlayedTime > 3) {
                [self.moviePlayer setCurrentPlaybackTime:self.moviePlayer.lastPlayedTime];
                self.moviePlayer.lastPlayedTime = 0;
            }

            if(self.video.summary.videoID) {
                [_dataInterface sendAnalyticsEvents:OEXVideoStateLoading withCurrentTime:0 forVideo:self.video];
            }

            [self showControls:nil];
            [self hideLoadingIndicators];
            if(self.stateBeforeSeek == MPMoviePlaybackStatePlaying) {
                [self.moviePlayer setCurrentPlaybackRate:_playbackRate];
                [self.moviePlayer play];
            }
            if(self.moviePlayer.autoPlaying == NO) {
                [self.moviePlayer pause];
            }
            self.state = CLVideoPlayerControlsStateReady;
            ELog(@"Load state ==> MPMovieLoadStatePlaythroughOK");
            break;

        case MPMovieLoadStateStalled:
            ELog(@"Load state ==> MovieStalled");
            self.state = CLVideoPlayerControlsStateLoading;
            [self showLoadingIndicators];
            break;
        case MPMovieLoadStateUnknown:
            ELog(@"Load state ==> Unknown");

            break;
        default:
            break;
    }
}

- (void)setDefaultPlaybackSpeed {
    self.playbackRate = 1.0;
    [self.moviePlayer setCurrentPlaybackRate:_playbackRate];
}

- (void)moviePlaybackStateDidChange:(NSNotification*)note {
    __weak CLVideoPlayerControls* weakSelf = self;

    NSString* strLanguage = [[NSString alloc] init];
    strLanguage = [OEXInterface getCCSelectedLanguage];
    switch(weakSelf.moviePlayer.playbackState)
    {
        case MPMoviePlaybackStateStopped:
            ELog(@"Playing state ==>> MPMoviePlaybackStateStopped");

		// Hide tables if video is stopped or ended
            [self didHideTables:YES];
		// CC implementation
		// Stop
            if(weakSelf.subtitleTimer.isValid) {
                [weakSelf.subtitleTimer invalidate];
            }
		// MOB -505

            weakSelf.state = CLVideoPlayerControlsStateIdle;
            weakSelf.playPauseButton.selected = YES;
            [weakSelf stopDurationTimer];
            [weakSelf stopBufferedTimer];
            break;

        case MPMoviePlaybackStatePlaying:
            ELog(@"Playing state ==>> MPMoviePlaybackStatePlaying");
            self.playPauseButton.selected = NO;
            [weakSelf startDurationTimer];
            [weakSelf startBufferedTimer];

		// Local file
            if([weakSelf.moviePlayer.contentURL.scheme isEqualToString:@"file"]) {
                [weakSelf setDurationSliderMaxMinValues];
                [weakSelf showControls:nil];
            }
            [weakSelf setUserInteractionEnabled:YES];
		// CC Implementaion
            [self initializeSubtitleWithTimer];
            break;

        case MPMoviePlaybackStatePaused:
            ELog(@"Playing state ==>> MPMoviePlaybackStatePaused");
            _playPauseButton.selected = YES;
		///TODO REVIEW CONDITION
            if(weakSelf.moviePlayer.loadState == MPMovieLoadStatePlaythroughOK ||
               weakSelf.moviePlayer.loadState == MPMovieLoadStateUnknown) {
                if(weakSelf.stateBeforeSeek == MPMoviePlaybackStatePlaying && !self.seeking) {
                    [weakSelf hideLoadingIndicators];
                    [weakSelf.moviePlayer play];
                }
            }
            break;

        case MPMoviePlaybackStateInterrupted:
            ELog(@"Playing state ==>> MPMoviePlaybackStateInterrupted");
            [weakSelf.moviePlayer pause];
            break;

        case MPMoviePlaybackStateSeekingForward:
            ELog(@"Playing state ==>> MPMoviePlaybackStateSeekingForward");
            [weakSelf stopDurationTimer];
            break;

        case MPMoviePlaybackStateSeekingBackward:
            ELog(@"Playing state ==>> MPMoviePlaybackStateSeekingBackward");
            [weakSelf stopDurationTimer];
            break;
        default:
            break;
    }

    if(weakSelf.moviePlayer.playbackState == MPMoviePlaybackStatePlaying) {
        weakSelf.playPauseButton.selected = NO;
    }
    else {
        weakSelf.playPauseButton.selected = YES;
    }
}

- (void)movieDurationAvailable:(NSNotification*)note {
    [self setDurationSliderMaxMinValues];
}

- (void)movieContentURLDidChange:(NSNotification*)note {
    if(self.moviePlayer.loadState != MPMovieLoadStatePlaythroughOK) {
        self.loadingContentUrl = YES;
    }
    [self hideControls:^{
	//don't show loading indicator for local files
         if([self.moviePlayer.contentURL.scheme isEqualToString:@"file"]) {
             self.state = CLVideoPlayerControlsStateReady;
         }
         else {
             self.state = CLVideoPlayerControlsStateLoading;
         }
     }];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if(self.style == CLVideoPlayerControlsStyleNone) {
        return;
    }

	//common sizes
    CGFloat paddingFromBezel = self.frame.size.width <= iPhoneScreenPortraitWidth ? 8.f : 10.f;

    CGFloat paddingBetweenLabelsAndSlider = 10.f;
    CGFloat sliderHeight = 34.f;//default height
    CGFloat labelWidth = 100.f;
    CGFloat paddingforFullscreen = 10.f;
    CGFloat rewindHeightWidth = 25.f;
    CGFloat settingsbtnSize = 24.f;
    CGFloat tableOptionWidth = 120.f;
    CGFloat tableOptionHeight = 88.f;
    CGFloat viewInnerWidth = 200.f;
    CGFloat viewInnerHeight = 240.f;
    CGFloat cancelButtonHeight = 44.f;
    CGFloat PrevNextButtonSize = 30.f;
    CGFloat LMSButtonSize = 15.f;

    CGFloat fullscreenBtnSize = 20.f;

    if(self.style == CLVideoPlayerControlsStyleFullscreen || (self.style == CLVideoPlayerControlsStyleDefault && self.moviePlayer.isFullscreen)) {
	//top bar
        self.topBar.frame = CGRectMake(0, 0, self.frame.size.width, self.barHeight);
        _videoTitleLabel.frame = CGRectMake(paddingFromBezel, 0, self.frame.size.width - (paddingFromBezel * 2) - LMSButtonSize, self.barHeight);

	//bottom bar
        self.bottomBar.frame = CGRectMake(0, self.frame.size.height - self.barHeight, self.frame.size.width, self.barHeight);
        self.fullscreenButton.frame = CGRectMake(self.bottomBar.frame.size.width - paddingforFullscreen - fullscreenBtnSize, self.barHeight / 2 - fullscreenBtnSize / 2, fullscreenBtnSize, fullscreenBtnSize);

	// RAHUL
	// For adjusting the option button
	// component position for CC , Next/Prev and Playbackspeed.

        self.btnSettings.frame = CGRectMake(self.fullscreenButton.frame.origin.x - settingsbtnSize - 15, self.barHeight / 2 - settingsbtnSize / 2, settingsbtnSize, settingsbtnSize);

        self.view_OptionsOverlay.frame = self.frame;

        self.table_Options.frame = CGRectMake(self.btnSettings.frame.origin.x - tableOptionWidth + (settingsbtnSize / 2), self.view_OptionsOverlay.frame.size.height - self.barHeight - tableOptionHeight, tableOptionWidth, tableOptionHeight);

        self.view_OptionsInner.frame = CGRectMake(self.btnSettings.frame.origin.x - viewInnerWidth + (settingsbtnSize / 2), self.view_OptionsOverlay.frame.size.height - self.barHeight - viewInnerHeight, viewInnerWidth, viewInnerHeight);

        self.table_Values.frame = CGRectMake(0, 0, viewInnerWidth, viewInnerHeight - cancelButtonHeight);

        self.btnCancel.frame = CGRectMake(10, viewInnerHeight - cancelButtonHeight, viewInnerWidth - 20, cancelButtonHeight);

        self.btnPrevious.frame = CGRectMake(paddingFromBezel, (self.frame.size.height / 2) - (PrevNextButtonSize / 2), PrevNextButtonSize, PrevNextButtonSize);

        self.btnNext.frame = CGRectMake(self.frame.size.width - paddingFromBezel - PrevNextButtonSize, (self.frame.size.height / 2) - (PrevNextButtonSize / 2), PrevNextButtonSize, PrevNextButtonSize);

        self.btnLMS.frame = CGRectMake(self.frame.size.width - paddingFromBezel - LMSButtonSize, 18, LMSButtonSize, LMSButtonSize);

        self.timeRemainingLabel.frame = CGRectMake(self.btnSettings.frame.origin.x - labelWidth, 0, labelWidth, self.barHeight);

        CGFloat playWidth = 42.f;
        CGFloat playHeight = 42.f;
        self.playPauseButton.frame = CGRectMake((self.frame.size.width / 2) - (playWidth / 2), (self.frame.size.height / 2) - (playHeight / 2), playWidth, playHeight);

        [_fullscreenButton setImage:[UIImage imageNamed:@"movieEndFullscreen.png"] forState:UIControlStateNormal];

	// Mob - 599 - Flexible popup
        [self changeCCPopUpSize];
    }
    else if(self.style == CLVideoPlayerControlsStyleEmbedded || (self.style == CLVideoPlayerControlsStyleDefault && !self.moviePlayer.isFullscreen)) {
        self.topBar.frame = CGRectMake(0, 0, self.frame.size.width, self.barHeight);

        _videoTitleLabel.frame = CGRectMake(paddingFromBezel, 0, self.frame.size.width - (paddingFromBezel * 2) - LMSButtonSize, self.barHeight);

        self.bottomBar.frame = CGRectMake(0, self.frame.size.height - self.barHeight, self.frame.size.width, self.barHeight);

	//right side of bottom bar

        self.fullscreenButton.frame = CGRectMake(self.bottomBar.frame.size.width - paddingforFullscreen - fullscreenBtnSize, self.barHeight / 2 - fullscreenBtnSize / 2, fullscreenBtnSize, fullscreenBtnSize);

	// RAHUL
	// For adjusting the option button
        self.btnSettings.frame = CGRectMake(self.fullscreenButton.frame.origin.x - settingsbtnSize - 15, self.barHeight / 2 - settingsbtnSize / 2, settingsbtnSize, settingsbtnSize);

        self.view_OptionsOverlay.frame = self.frame;

        self.table_Options.frame = CGRectMake(self.btnSettings.frame.origin.x - tableOptionWidth + (settingsbtnSize / 2), self.view_OptionsOverlay.frame.size.height - self.barHeight - tableOptionHeight, tableOptionWidth, tableOptionHeight);

        self.timeRemainingLabel.frame = CGRectMake(self.btnSettings.frame.origin.x - labelWidth, 0, labelWidth, self.barHeight);

        self.btnLMS.frame = CGRectMake(self.frame.size.width - paddingFromBezel - LMSButtonSize, 18, LMSButtonSize, LMSButtonSize);

        CGFloat playWidth = 35.f;
        CGFloat playHeight = 35.f;
        self.playPauseButton.frame = CGRectMake((self.frame.size.width / 2) - (playWidth / 2), (self.frame.size.height / 2) - (playHeight / 2), playWidth, playHeight);

        [_fullscreenButton setImage:[UIImage imageNamed:@"movieFullscreen.png"] forState:UIControlStateNormal];
    }

    self.rewindButton.frame = CGRectMake(paddingFromBezel, self.barHeight / 2 - rewindHeightWidth / 2 + 1.f, rewindHeightWidth, rewindHeightWidth);

	//duration slider
    CGFloat timeRemainingX = self.timeRemainingLabel.frame.origin.x;

    CGFloat backwordbtnX = self.rewindButton.frame.origin.x;

    _videoTitleLabel.text = _moviePlayer.videoTitle;

    CGFloat sliderWidth = ((timeRemainingX ) - (backwordbtnX + self.rewindButton.frame.size.width + paddingBetweenLabelsAndSlider));

    self.durationSlider.frame = CGRectMake(backwordbtnX + self.rewindButton.frame.size.width + paddingBetweenLabelsAndSlider, self.barHeight / 2 - sliderHeight / 2, sliderWidth, sliderHeight);

    [self updateComponentsOriginOnOrientation];

    [_activityBackgroundView setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    [_activityIndicator setFrame:CGRectMake((self.frame.size.width / 2) - (activityIndicatorSize / 2), (self.frame.size.height / 2) - (activityIndicatorSize / 2), activityIndicatorSize, activityIndicatorSize)];

    [self didHidePrevNext];
}

@end

# pragma mark - CLMoviePlayerControlsBar

@implementation CLMoviePlayerControlsBar

- (id)init {
    if(self = [super init]) {
        self.opaque = NO;
    }
    return self;
}

- (void)setColor:(UIColor*)color {
    if(_color != color) {
        _color = color;
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [_color CGColor]);
    CGContextFillRect(context, rect);
}

@end
