//
//  BadgesModel.swift
//  edX
//
//  Created by Akiva Leffert on 3/31/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

public struct BadgeClass {

    public let slug : String?
    public let issuingComponent : String?
    public let name : String
    public let detail : String?
    public let imageURL : String?
    public let courseID : String?

    fileprivate enum Fields : String, RawStringExtractable {
        case Slug = "slug"
        case IssuingComponent = "issuing_component"
        case DisplayName = "display_name"
        case Description = "description"
        case ImageURL = "image_url"
        case CourseID = "course_id"
    }

    public init(slug: String? = nil, issuingComponent: String? = nil, name: String, detail: String? = nil, imageURL: String? = nil, courseID: String? = nil) {
        self.slug = slug
        self.issuingComponent = issuingComponent
        self.name = name
        self.detail = detail
        self.imageURL = imageURL
        self.courseID = courseID
    }

    public init?(json : JSON) {
        guard let name = json[Fields.DisplayName].string else { return nil }
        self.slug = json[Fields.Slug].string
        self.issuingComponent = json[Fields.IssuingComponent].string
        self.name = name
        self.detail = json[Fields.Description].string
        self.imageURL = json[Fields.ImageURL].string
        self.courseID = json[Fields.CourseID].string
    }
}

public struct BadgeAssertion {
    public let assertionURL : URL
    public let imageURL : String
    public let created : NSDate?
    public let badgeClass : BadgeClass

    fileprivate enum Fields : String, RawStringExtractable {
        case Username = "username"
        case AssertionURL = "assertion_url"
        case ImageURL = "image_url"
        case Created = "created"
        case BadgeClass = "badge_class"
    }

    public init(assertionURL: URL, imageURL: String, created: NSDate? = nil, badgeClass: BadgeClass) {
        self.assertionURL = assertionURL
        self.imageURL = imageURL
        self.created = created
        self.badgeClass = badgeClass
    }

    public init?(json : JSON) {
        guard let
            badgeClass = BadgeClass(json: json[Fields.BadgeClass]),
            let assertionURL = json[Fields.AssertionURL].url,
            let imageURL = json[Fields.ImageURL].string ?? badgeClass.imageURL
        else {
                return nil
        }
        self.assertionURL = assertionURL as URL
        self.imageURL = imageURL
        created = json[Fields.Created].serverDate
        self.badgeClass = badgeClass
    }
}
