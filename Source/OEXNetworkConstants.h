//
//  OEXNetworkConstants.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 22/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#ifndef edXVideoLocker_NetworkConstants_h
#define edXVideoLocker_NetworkConstants_h

//NSNotification center constants
#define DOWNLOAD_PROGRESS_NOTIFICATION @"downloadProgressNotification"
#define DOWNLOAD_PROGRESS_NOTIFICATION_TASK @"downloadProgressNotificationTask"
#define DOWNLOAD_PROGRESS_NOTIFICATION_TOTAL_BYTES_WRITTEN @"downloadProgressNotificationTotalBytesWritten"
#define DOWNLOAD_PROGRESS_NOTIFICATION_TOTAL_BYTES_TO_WRITE @"downloadProgressNotificationTotalBytesToWrite"

#define REQUEST_USER_DETAILS @"User details"
#define REQUEST_COURSE_ENROLLMENTS @"Courses user has enrolled in"

// edX Constants

// TODO: move the remaining things that mention edx.org into config
#define URL_EXTENSION_VIDEOS @".mp4"
#define URL_EXCHANGE_TOKEN @"/oauth2/exchange_access_token/{backend}/"
#define URL_USER_DETAILS @"/api/mobile/v0.5/users"
#define URL_COURSE_ENROLLMENTS @"/course_enrollments/"
#define URL_VIDEO_SUMMARY @"/api/mobile/v0.5/video_outlines/courses/"
#define URL_COURSE_HANDOUTS @"/handouts"
#define URL_COURSE_ANNOUNCEMENTS @"/updates"
#define URL_RESET_PASSWORD  @"/password_reset/"
#define URL_SUBSTRING_VIDEOS @"edx-course-videos"
#define URL_SUBSTRING_ASSETS @"asset/"
#define AUTHORIZATION_URL @"/oauth2/access_token"
#define URL_GET_USER_INFO @"/api/mobile/v0.5/my_user_info"
// For Closed Captioning
#define URL_VIDEO_SRT_FILE @"/api/mobile/v0.5/video_outlines/transcript/"
#define URL_COURSE_ENROLLMENT @"/api/enrollment/v1/enrollment"
#define URL_COURSE_ENROLLMENT_EMAIL_OPT_IN @"/api/user_api/v1/preferences/email_opt_in"
#define SIGN_UP_URL @"/user_api/v1/account/registration/"

#endif
