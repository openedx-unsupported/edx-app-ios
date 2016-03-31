//
//  BadgesModel.swift
//  edX
//
//  Created by Akiva Leffert on 3/31/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

public struct BadgeSpec {

    let slug : String
    let issuingComponent : String
    let name : String
    let description : String
    let imageURL : NSURL
    let courseID : String

    private enum Fields : String, RawStringExtractable {
        case Slug = "slug"
        case IssuingComponent = "issuing_component"
        case Name = "name"
        case Description = "description"
        case ImageURL = "image_url"
        case CourseID = "course_id"
    }

    public init?(json : JSON) {
        guard let
            slug = json[Fields.Slug].string,
            issuingComponent = json[Fields.IssuingComponent].string,
            name = json[Fields.Name].string,
            description = json[Fields.Description].string,
            imageURL = json[Fields.ImageURL].URL,
            courseID = json[Fields.CourseID].string
            else {
                return nil
        }
        self.issuingComponent = issuingComponent
        self.slug = slug
        self.name = name
        self.description = description
        self.imageURL = imageURL
        self.courseID = courseID
    }
}

public struct BadgeAssertion {
    let username : String
    let evidence : NSURL
    let imageURL : NSURL
    let awardedOn : NSDate
    let spec : BadgeSpec


    private enum Fields : String, RawStringExtractable {
        case Username = "username"
        case Evidence = "evidence"
        case ImageURL = "image_url"
        case AwardedOn = "awarded_on"
        case Spec = "spec"
    }

    public init?(json : JSON) {
        guard let
            username = json[Fields.Username].string,
            evidence = json[Fields.Evidence].URL,
            imageURL = json[Fields.ImageURL].URL,
            awardedOn = json[Fields.AwardedOn].serverDate,
            spec = BadgeSpec(json: json[Fields.Spec])
            else {
                return nil
        }
        self.username = username
        self.evidence = evidence
        self.imageURL = imageURL
        self.awardedOn = awardedOn
        self.spec = spec
    }
}
