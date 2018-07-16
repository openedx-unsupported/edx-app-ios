//
//  WebViewEnums.swift
//  edX
//
//  Created by Zeeshan Arif on 7/13/18.
//  Copyright © 2018 edX. All rights reserved.
//

import Foundation

enum AppURLString: String {
    case appURLScheme = "edxapp"
    case pathPlaceHolder = "{path_id}"
}

enum AppURLParameterKey: String, RawStringExtractable {
    case pathId = "path_id";
    case courseId = "course_id"
    case emailOptIn = "email_opt_in"
}

// Define Your Hosts Here
enum AppURLHost: String {
    case courseEnrollment = "enroll"
    case courseDetail = "course_info"
    case enrolledCourseDetail = "enrolled_course_info"
    case enrolledProgramDetail = "enrolled_program_info"
}
