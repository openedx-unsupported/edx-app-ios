//
//  BadgesModel.swift
//  edX
//
//  Created by Akiva Leffert on 3/31/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

public struct BadgeSpec {

    public let slug : String?
    public let issuingComponent : String?
    public let name : String
    public let detail : String?
    public let imageURL : String?
    public let courseID : String?

    private enum Fields : String, RawStringExtractable {
        case Slug = "slug"
        case IssuingComponent = "issuing_component"
        case Name = "name"
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
        guard let name = json[Fields.Name].string else { return nil }
        self.slug = json[Fields.Slug].string
        self.issuingComponent = json[Fields.IssuingComponent].string
        self.name = name
        self.detail = json[Fields.Description].string
        self.imageURL = json[Fields.ImageURL].string
        self.courseID = json[Fields.CourseID].string
    }
}

public struct BadgeAssertion {
    public let username : String?
    public let evidence : NSURL
    public let imageURL : String
    public let awardedOn : NSDate?
    public let spec : BadgeSpec

    private enum Fields : String, RawStringExtractable {
        case Username = "username"
        case Evidence = "evidence"
        case ImageURL = "image_url"
        case AwardedOn = "awarded_on"
        case Spec = "spec"
    }

    public init(username: String? = nil, evidence: NSURL, imageURL: String, awardedOn: NSDate? = nil, spec: BadgeSpec) {
        self.username = username
        self.evidence = evidence
        self.imageURL = imageURL
        self.awardedOn = awardedOn
        self.spec = spec
    }

    public init?(json : JSON) {
        guard let
            spec = BadgeSpec(json: json[Fields.Spec]),
            evidence = json[Fields.Evidence].URL,
            imageURL = json[Fields.ImageURL].string ?? spec.imageURL
        else {
                return nil
        }
        self.evidence = evidence
        self.imageURL = imageURL
        self.username = json[Fields.Username].string
        self.awardedOn = json[Fields.AwardedOn].serverDate
        self.spec = spec
    }
}
