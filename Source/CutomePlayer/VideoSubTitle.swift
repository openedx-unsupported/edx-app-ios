//
//  VideoSubTitle.swift
//  edX
//
//  Created by Salman on 29/03/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

protocol VideoSubTitleDelegate: class {
    func subTitleLoaded(transcripts: [SubTitle])
}

class VideoSubTitle: NSObject {

    let video: OEXHelperVideoDownload
    let dataInterface = OEXInterface.shared()
    let subTitleParser = SubTitleParser()
    var subTitles: [SubTitle] = []
    var delegate: VideoSubTitleDelegate?
    
    init(with video: OEXHelperVideoDownload) {
        self.video = video
        super.init()
    }
    
    func initializeSubtitle() {
        var captionURL : String = ""
        if let ccSelectedLanguage = OEXInterface.getCCSelectedLanguage(), let url = video.summary?.transcripts?[ccSelectedLanguage] as? String, ccSelectedLanguage != "", url != ""{
            captionURL = url
        
            
        } else if let url = video.summary?.transcripts?.values.first as? String  {
            captionURL = url
        }
        getClosedCaptioningFile(atURL: captionURL)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadedTranscript), name: NSNotification.Name(rawValue: DL_COMPLETE), object: nil)
    }
    
    func downloadedTranscript(note: Notification) {
        if let task = note.userInfo?[DL_COMPLETE_N_TASK] as? URLSessionDownloadTask, let taskURL = task.response?.url {
            var captionURL: String = ""
            if let ccSelectedLanguage = OEXInterface.getCCSelectedLanguage(), let url = video.summary?.transcripts?[ccSelectedLanguage] as? String{
                captionURL = url
            }
            else if let url = video.summary?.transcripts?.values.first as? String  {
                captionURL = url
            }
            
            if taskURL.absoluteString == captionURL {
                getClosedCaptioningFile(atURL: captionURL)
            }
        }
    }
    
   private func getClosedCaptioningFile(atURL URLString: String?) {
        if let localFile: String = OEXFileUtility.filePath(forRequestKey: URLString) {
            var subtitleString = ""
            // File to string
            if FileManager.default.fileExists(atPath: localFile) {
                // File to string
                do {
                    let subTitle = try String(contentsOfFile: localFile, encoding: .utf8)
                    subtitleString = subTitle.replacingOccurrences(of: "\r", with:"\n")
                    subTitleParser.parse(subTitlesString: subtitleString, completion: { (success, error) in
                        subTitles = subTitleParser.subTitles
                        delegate?.subTitleLoaded(transcripts: subTitles)
                    })
                }
                catch let error {
                }
            }
            else {
                dataInterface.download(withRequest: URLString, forceUpdate: false)
            }
        }
    }
    
    func getSubTitle(at time: TimeInterval) -> String {
        let filteredSubTitles = subTitles.filter { return time > $0.start && time < $0.end }
        return filteredSubTitles.first?.text ?? ""
    }
}
