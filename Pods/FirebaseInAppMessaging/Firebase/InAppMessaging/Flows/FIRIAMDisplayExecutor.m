/*
 * Copyright 2017 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <FirebaseCore/FIRLogger.h>

#import "FIRCore+InAppMessaging.h"
#import "FIRIAMActivityLogger.h"
#import "FIRIAMDisplayExecutor.h"
#import "FIRIAMMessageContentData.h"
#import "FIRIAMMessageDefinition.h"
#import "FIRIAMSDKRuntimeErrorCodes.h"
#import "FIRInAppMessaging.h"

@implementation FIRIAMDisplaySetting
@end

@interface FIRIAMDisplayExecutor () <FIRInAppMessagingDisplayDelegate>
@property(nonatomic) id<FIRIAMTimeFetcher> timeFetcher;

// YES if a message is being rendered at this time
@property(nonatomic) BOOL isMsgBeingDisplayed;
@property(nonatomic) NSTimeInterval lastDisplayTime;
@property(nonatomic, nonnull, readonly) FIRInAppMessaging *inAppMessaging;
@property(nonatomic, nonnull, readonly) FIRIAMDisplaySetting *setting;
@property(nonatomic, nonnull, readonly) FIRIAMMessageClientCache *messageCache;
@property(nonatomic, nonnull, readonly) id<FIRIAMBookKeeper> displayBookKeeper;
@property(nonatomic) BOOL impressionRecorded;
@property(nonatomic, nonnull, readonly) id<FIRIAMAnalyticsEventLogger> analyticsEventLogger;
@property(nonatomic, nonnull, readonly) FIRIAMActionURLFollower *actionURLFollower;
@end

@implementation FIRIAMDisplayExecutor {
  FIRIAMMessageDefinition *_currentMsgBeingDisplayed;
}

#pragma mark - FIRInAppMessagingDisplayDelegate methods
- (void)messageClicked:(FIRInAppMessagingDisplayMessage *)inAppMessage {
  // Call through to app-side delegate.
  __weak id<FIRInAppMessagingDisplayDelegate> appSideDelegate = self.inAppMessaging.delegate;
  if ([appSideDelegate respondsToSelector:@selector(messageClicked:)]) {
    [appSideDelegate messageClicked:inAppMessage];
  }

  self.isMsgBeingDisplayed = NO;
  if (!_currentMsgBeingDisplayed.renderData.messageID) {
    FIRLogWarning(kFIRLoggerInAppMessaging, @"I-IAM400030",
                  @"messageClicked called but "
                   "there is no current message ID.");
    return;
  }

  if (_currentMsgBeingDisplayed.isTestMessage) {
    FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400031",
                @"A test message clicked. Do test event impression/click analytics logging");

    [self.analyticsEventLogger
        logAnalyticsEventForType:FIRIAMAnalyticsEventTestMessageImpression
                   forCampaignID:_currentMsgBeingDisplayed.renderData.messageID
                withCampaignName:_currentMsgBeingDisplayed.renderData.name
                   eventTimeInMs:nil
                      completion:^(BOOL success) {
                        FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400036",
                                    @"Logging analytics event for url following %@",
                                    success ? @"succeeded" : @"failed");
                      }];

    [self.analyticsEventLogger
        logAnalyticsEventForType:FIRIAMAnalyticsEventTestMessageClick
                   forCampaignID:_currentMsgBeingDisplayed.renderData.messageID
                withCampaignName:_currentMsgBeingDisplayed.renderData.name
                   eventTimeInMs:nil
                      completion:^(BOOL success) {
                        FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400039",
                                    @"Logging analytics event for url following %@",
                                    success ? @"succeeded" : @"failed");
                      }];
  } else {
    // Logging the impression
    [self recordValidImpression:_currentMsgBeingDisplayed.renderData.messageID
                withMessageName:_currentMsgBeingDisplayed.renderData.name];

    [self.analyticsEventLogger
        logAnalyticsEventForType:FIRIAMAnalyticsEventActionURLFollow
                   forCampaignID:_currentMsgBeingDisplayed.renderData.messageID
                withCampaignName:_currentMsgBeingDisplayed.renderData.name
                   eventTimeInMs:nil
                      completion:^(BOOL success) {
                        FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400032",
                                    @"Logging analytics event for url following %@",
                                    success ? @"succeeded" : @"failed");
                      }];
  }

  NSURL *actionURL = _currentMsgBeingDisplayed.renderData.contentData.actionURL;

  if (!actionURL) {
    FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400033",
                @"messageClicked called but "
                 "there is no action url specified in the message data.");
    // it's equivalent to closing the message with no further action
    return;
  } else {
    FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400037", @"Following action url %@",
                actionURL.absoluteString);
    @try {
      [self.actionURLFollower
              followActionURL:actionURL
          withCompletionBlock:^(BOOL success) {
            FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400034",
                        @"Seeing %@ from following action URL", success ? @"success" : @"error");
          }];
    } @catch (NSException *e) {
      FIRLogWarning(kFIRLoggerInAppMessaging, @"I-IAM400035",
                    @"Exception encountered in following "
                     "action url (%@): %@ ",
                    actionURL, e.description);
      @throw;
    }
  }
}

- (void)messageDismissed:(FIRInAppMessagingDisplayMessage *)inAppMessage
             dismissType:(FIRInAppMessagingDismissType)dismissType {
  // Call through to app-side delegate.
  __weak id<FIRInAppMessagingDisplayDelegate> appSideDelegate = self.inAppMessaging.delegate;
  if ([appSideDelegate respondsToSelector:@selector(messageDismissed:dismissType:)]) {
    [appSideDelegate messageDismissed:inAppMessage dismissType:dismissType];
  }

  self.isMsgBeingDisplayed = NO;
  if (!_currentMsgBeingDisplayed.renderData.messageID) {
    FIRLogWarning(kFIRLoggerInAppMessaging, @"I-IAM400014",
                  @"messageDismissedWithType called but "
                   "there is no current message ID.");
    return;
  }

  if (_currentMsgBeingDisplayed.isTestMessage) {
    FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400020",
                @"A test message dismissed. Record the impression event.");
    [self.analyticsEventLogger
        logAnalyticsEventForType:FIRIAMAnalyticsEventTestMessageImpression
                   forCampaignID:_currentMsgBeingDisplayed.renderData.messageID
                withCampaignName:_currentMsgBeingDisplayed.renderData.name
                   eventTimeInMs:nil
                      completion:^(BOOL success) {
                        FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400038",
                                    @"Logging analytics event for url following %@",
                                    success ? @"succeeded" : @"failed");
                      }];

    return;
  }

  // Logging the impression
  [self recordValidImpression:_currentMsgBeingDisplayed.renderData.messageID
              withMessageName:_currentMsgBeingDisplayed.renderData.name];

  FIRIAMAnalyticsLogEventType logEventType = dismissType == FIRInAppMessagingDismissTypeAuto
                                                 ? FIRIAMAnalyticsEventMessageDismissAuto
                                                 : FIRIAMAnalyticsEventMessageDismissClick;

  [self.analyticsEventLogger
      logAnalyticsEventForType:logEventType
                 forCampaignID:_currentMsgBeingDisplayed.renderData.messageID
              withCampaignName:_currentMsgBeingDisplayed.renderData.name
                 eventTimeInMs:nil
                    completion:^(BOOL success) {
                      FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400004",
                                  @"Logging analytics event for message dismiss %@",
                                  success ? @"succeeded" : @"failed");
                    }];
}

- (void)impressionDetectedForMessage:(FIRInAppMessagingDisplayMessage *)inAppMessage {
  __weak id<FIRInAppMessagingDisplayDelegate> appSideDelegate = self.inAppMessaging.delegate;
  if ([appSideDelegate respondsToSelector:@selector(impressionDetectedForMessage:)]) {
    [appSideDelegate impressionDetectedForMessage:inAppMessage];
  }

  if (!_currentMsgBeingDisplayed.renderData.messageID) {
    FIRLogWarning(kFIRLoggerInAppMessaging, @"I-IAM400022",
                  @"impressionDetected called but "
                   "there is no current message ID.");
    return;
  }

  if (!_currentMsgBeingDisplayed.isTestMessage) {
    // Displayed long enough to be a valid impression.
    [self recordValidImpression:_currentMsgBeingDisplayed.renderData.messageID
                withMessageName:_currentMsgBeingDisplayed.renderData.name];
  } else {
    FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400011",
                @"A test message. Record the test message impression event.");
    return;
  }
}

- (void)displayErrorForMessage:(FIRInAppMessagingDisplayMessage *)inAppMessage
                         error:(NSError *)error {
  __weak id<FIRInAppMessagingDisplayDelegate> appSideDelegate = self.inAppMessaging.delegate;
  if ([appSideDelegate respondsToSelector:@selector(displayErrorForMessage:error:)]) {
    [appSideDelegate displayErrorForMessage:inAppMessage error:error];
  }

  self.isMsgBeingDisplayed = NO;

  if (!_currentMsgBeingDisplayed.renderData.messageID) {
    FIRLogWarning(kFIRLoggerInAppMessaging, @"I-IAM400017",
                  @"displayErrorEncountered called but "
                   "there is no current message ID.");
    return;
  }

  NSString *messageID = _currentMsgBeingDisplayed.renderData.messageID;

  FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400009",
              @"Display ran into error for message %@: %@", messageID, error);

  if (_currentMsgBeingDisplayed.isTestMessage) {
    [self displayMessageLoadError:error];
    FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400012",
                @"A test message. No analytics tracking "
                 "from image data loading failure");
    return;
  }

  // we remove the message from the client side cache so that it won't be retried until next time
  // it's fetched again from server.
  [self.messageCache removeMessageWithId:messageID];
  NSString *messageName = _currentMsgBeingDisplayed.renderData.name;

  if ([error.domain isEqualToString:NSURLErrorDomain]) {
    [self.analyticsEventLogger
        logAnalyticsEventForType:FIRIAMAnalyticsEventImageFetchError
                   forCampaignID:messageID
                withCampaignName:messageName
                   eventTimeInMs:nil
                      completion:^(BOOL success) {
                        FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400010",
                                    @"Logging analytics event for image fetch error %@",
                                    success ? @"succeeded" : @"failed");
                      }];
  } else if (error.code == FIRIAMSDKRuntimeErrorNonImageMimetypeFromImageURL) {
    [self.analyticsEventLogger
        logAnalyticsEventForType:FIRIAMAnalyticsEventImageFormatUnsupported
                   forCampaignID:messageID
                withCampaignName:messageName
                   eventTimeInMs:nil
                      completion:^(BOOL success) {
                        FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400013",
                                    @"Logging analytics event for image format error %@",
                                    success ? @"succeeded" : @"failed");
                      }];
  }
}

- (void)recordValidImpression:(NSString *)messageID withMessageName:(NSString *)messageName {
  if (!self.impressionRecorded) {
    [self.displayBookKeeper recordNewImpressionForMessage:messageID
                              withStartTimestampInSeconds:self.lastDisplayTime];
    self.impressionRecorded = YES;
    [self.messageCache removeMessageWithId:messageID];
    // Log an impression analytics event as well.
    [self.analyticsEventLogger
        logAnalyticsEventForType:FIRIAMAnalyticsEventMessageImpression
                   forCampaignID:messageID
                withCampaignName:messageName
                   eventTimeInMs:nil
                      completion:^(BOOL success) {
                        FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400007",
                                    @"Logging analytics event for impression %@",
                                    success ? @"succeeded" : @"failed");
                      }];
  }
}

- (void)displayMessageLoadError:(NSError *)error {
  NSString *errorMsg = error.userInfo[NSLocalizedDescriptionKey]
                           ? error.userInfo[NSLocalizedDescriptionKey]
                           : @"Message loading failed";
  UIAlertController *alert = [UIAlertController
      alertControllerWithTitle:@"Firebase InAppMessaging fail to load a test message"
                       message:errorMsg
                preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action){
                                                        }];

  [alert addAction:defaultAction];

  [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert
                                                                               animated:YES
                                                                             completion:nil];
}

- (instancetype)initWithInAppMessaging:(FIRInAppMessaging *)inAppMessaging
                               setting:(FIRIAMDisplaySetting *)setting
                          messageCache:(FIRIAMMessageClientCache *)cache
                           timeFetcher:(id<FIRIAMTimeFetcher>)timeFetcher
                            bookKeeper:(id<FIRIAMBookKeeper>)displayBookKeeper
                     actionURLFollower:(FIRIAMActionURLFollower *)actionURLFollower
                        activityLogger:(FIRIAMActivityLogger *)activityLogger
                  analyticsEventLogger:(id<FIRIAMAnalyticsEventLogger>)analyticsEventLogger {
  if (self = [super init]) {
    _inAppMessaging = inAppMessaging;
    _timeFetcher = timeFetcher;
    _lastDisplayTime = displayBookKeeper.lastDisplayTime;
    _setting = setting;
    _messageCache = cache;
    _displayBookKeeper = displayBookKeeper;
    _isMsgBeingDisplayed = NO;
    _analyticsEventLogger = analyticsEventLogger;
    _actionURLFollower = actionURLFollower;
    _suppressMessageDisplay = NO;  // always allow message display on startup
  }
  return self;
}

- (void)checkAndDisplayNextContextualMessageForAnalyticsEvent:(NSString *)eventName {
  // synchronizing on self so that we won't potentially enter the render flow from two
  // threads: example like showing analytics triggered message and a regular app open
  // triggered message
  @synchronized(self) {
    if (self.suppressMessageDisplay) {
      FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400015",
                  @"Message display is being suppressed. No contextual message rendering.");
      return;
    }

    if (!self.messageDisplayComponent) {
      FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400026",
                  @"Message display component is not present yet. No display should happen.");
      return;
    }

    if (self.isMsgBeingDisplayed) {
      FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400008",
                  @"An in-app message display is in progress, do not check analytics event "
                   "based message for now.");

      return;
    }

    // Pop up next analytics event based message to be displayed
    FIRIAMMessageDefinition *nextAnalyticsBasedMessage =
        [self.messageCache nextOnFirebaseAnalyticEventDisplayMsg:eventName];

    if (nextAnalyticsBasedMessage) {
      [self displayForMessage:nextAnalyticsBasedMessage
                  triggerType:FIRInAppMessagingDisplayTriggerTypeOnAnalyticsEvent];
    }
  }
}

- (FIRInAppMessagingBannerDisplay *)
    bannerMessageWithMessageDefinition:(FIRIAMMessageDefinition *)definition
                             imageData:(FIRInAppMessagingImageData *)imageData
                           triggerType:(FIRInAppMessagingDisplayTriggerType)triggerType {
  NSString *title = definition.renderData.contentData.titleText;
  NSString *body = definition.renderData.contentData.bodyText;

  FIRInAppMessagingBannerDisplay *bannerMessage = [[FIRInAppMessagingBannerDisplay alloc]
        initWithMessageID:definition.renderData.messageID
             campaignName:definition.renderData.name
      renderAsTestMessage:definition.isTestMessage
              triggerType:triggerType
                titleText:title
                 bodyText:body
                textColor:definition.renderData.renderingEffectSettings.textColor
          backgroundColor:definition.renderData.renderingEffectSettings.displayBGColor
                imageData:imageData
                actionURL:definition.renderData.contentData.actionURL];

  return bannerMessage;
}

- (FIRInAppMessagingImageOnlyDisplay *)
    imageOnlyMessageWithMessageDefinition:(FIRIAMMessageDefinition *)definition
                                imageData:(FIRInAppMessagingImageData *)imageData
                              triggerType:(FIRInAppMessagingDisplayTriggerType)triggerType {
  FIRInAppMessagingImageOnlyDisplay *imageOnlyMessage = [[FIRInAppMessagingImageOnlyDisplay alloc]
        initWithMessageID:definition.renderData.messageID
             campaignName:definition.renderData.name
      renderAsTestMessage:definition.isTestMessage
              triggerType:triggerType
                imageData:imageData
                actionURL:definition.renderData.contentData.actionURL];

  return imageOnlyMessage;
}

- (FIRInAppMessagingModalDisplay *)
    modalViewMessageWithMessageDefinition:(FIRIAMMessageDefinition *)definition
                                imageData:(FIRInAppMessagingImageData *)imageData
                              triggerType:(FIRInAppMessagingDisplayTriggerType)triggerType {
  // For easier reference in this method.
  FIRIAMMessageRenderData *renderData = definition.renderData;

  NSString *title = renderData.contentData.titleText;
  NSString *body = renderData.contentData.bodyText;

  FIRInAppMessagingActionButton *actionButton = nil;

  if (definition.renderData.contentData.actionButtonText) {
    actionButton = [[FIRInAppMessagingActionButton alloc]
        initWithButtonText:renderData.contentData.actionButtonText
           buttonTextColor:renderData.renderingEffectSettings.btnTextColor
           backgroundColor:renderData.renderingEffectSettings.btnBGColor];
  }

  FIRInAppMessagingModalDisplay *modalViewMessage = [[FIRInAppMessagingModalDisplay alloc]
        initWithMessageID:definition.renderData.messageID
             campaignName:definition.renderData.name
      renderAsTestMessage:definition.isTestMessage
              triggerType:triggerType
                titleText:title
                 bodyText:body
                textColor:renderData.renderingEffectSettings.textColor
          backgroundColor:renderData.renderingEffectSettings.displayBGColor
                imageData:imageData
             actionButton:actionButton
                actionURL:definition.renderData.contentData.actionURL];

  return modalViewMessage;
}

- (FIRInAppMessagingDisplayMessage *)
    displayMessageWithMessageDefinition:(FIRIAMMessageDefinition *)definition
                              imageData:(FIRInAppMessagingImageData *)imageData
                            triggerType:(FIRInAppMessagingDisplayTriggerType)triggerType {
  switch (definition.renderData.renderingEffectSettings.viewMode) {
    case FIRIAMRenderAsBannerView:
      return [self bannerMessageWithMessageDefinition:definition
                                            imageData:imageData
                                          triggerType:triggerType];
    case FIRIAMRenderAsModalView:
      return [self modalViewMessageWithMessageDefinition:definition
                                               imageData:imageData
                                             triggerType:triggerType];
    case FIRIAMRenderAsImageOnlyView:
      return [self imageOnlyMessageWithMessageDefinition:definition
                                               imageData:imageData
                                             triggerType:triggerType];
    default:
      return nil;
  }
}

- (void)displayForMessage:(FIRIAMMessageDefinition *)message
              triggerType:(FIRInAppMessagingDisplayTriggerType)triggerType {
  _currentMsgBeingDisplayed = message;
  [message.renderData.contentData
      loadImageDataWithBlock:^(NSData *_Nullable imageNSData, NSError *error) {
        FIRInAppMessagingImageData *imageData = nil;

        if (error) {
          FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400019",
                      @"Error in loading image data for the message.");

          FIRInAppMessagingDisplayMessage *erroredMessage =
              [self displayMessageWithMessageDefinition:message
                                              imageData:imageData
                                            triggerType:triggerType];
          // short-circuit to display error handling
          [self displayErrorForMessage:erroredMessage error:error];
          return;
        } else if (imageNSData != nil) {
          imageData = [[FIRInAppMessagingImageData alloc]
              initWithImageURL:message.renderData.contentData.imageURL.absoluteString
                     imageData:imageNSData];
        }

        self.impressionRecorded = NO;
        self.isMsgBeingDisplayed = YES;

        FIRInAppMessagingDisplayMessage *displayMessage =
            [self displayMessageWithMessageDefinition:message
                                            imageData:imageData
                                          triggerType:triggerType];
        [self.messageDisplayComponent displayMessage:displayMessage displayDelegate:self];
      }];
}

- (BOOL)enoughIntervalFromLastDisplay {
  NSTimeInterval intervalFromLastDisplayInSeconds =
      [self.timeFetcher currentTimestampInSeconds] - self.lastDisplayTime;

  FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400005",
              @"Interval time from last display is %lf seconds", intervalFromLastDisplayInSeconds);

  return intervalFromLastDisplayInSeconds >= self.setting.displayMinIntervalInMinutes * 60.0;
}

- (void)checkAndDisplayNextAppForegroundMessage {
  // synchronizing on self so that we won't potentially enter the render flow from two
  // threads: example like showing analytics triggered message and a regular app open
  // triggered message concurrently
  @synchronized(self) {
    if (!self.messageDisplayComponent) {
      FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400027",
                  @"Message display component is not present yet. No display should happen.");
      return;
    }

    if (self.suppressMessageDisplay) {
      FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400016",
                  @"Message display is being suppressed. No regular message rendering.");
      return;
    }

    if (self.isMsgBeingDisplayed) {
      FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400002",
                  @"An in-app message display is in progress, do not over-display on top of it.");
      return;
    }

    if ([self.messageCache hasTestMessage] || [self enoughIntervalFromLastDisplay]) {
      // We can display test messages anytime or display regular messages when
      // the display time interval has been reached
      FIRIAMMessageDefinition *nextForegroundMessage = [self.messageCache nextOnAppOpenDisplayMsg];

      if (nextForegroundMessage) {
        [self displayForMessage:nextForegroundMessage
                    triggerType:FIRInAppMessagingDisplayTriggerTypeOnAppForeground];
        self.lastDisplayTime = [self.timeFetcher currentTimestampInSeconds];
      } else {
        FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400001",
                    @"No appropriate in-app message detected for display.");
      }
    } else {
      FIRLogDebug(kFIRLoggerInAppMessaging, @"I-IAM400003",
                  @"Minimal display interval of %lf seconds has not been reached yet.",
                  self.setting.displayMinIntervalInMinutes * 60.0);
    }
  }
}
@end
