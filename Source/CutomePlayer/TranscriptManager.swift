//
//  TranscriptManager.swift
//  edX
//
//  Created by Salman on 29/03/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

protocol TranscriptManagerDelegate: class {
    func transcriptsLoaded(manager: TranscriptManager, transcripts: [TranscriptObject])
}

class TranscriptManager: NSObject {
    
    typealias Environment = OEXInterfaceProvider
    
    let environment : Environment
    private let video: OEXHelperVideoDownload
    private let transcriptParser = TranscriptParser()
    private var transcripts: [TranscriptObject] = []
    var delegate: TranscriptManagerDelegate? {
        didSet {
            initializeSubtitle()
        }
    }
    
    init(environment: Environment, video: OEXHelperVideoDownload) {
        self.environment = environment
        self.video = video
        super.init()
    }
    
    private func initializeSubtitle() {
        let captionURL = getCaptionURL()
        getClosedCaptioningFile(atURL: captionURL)
        NotificationCenter.default.oex_addObserver(observer: self, name: DL_COMPLETE) { (notification, _, _) -> Void in
            self.downloadedTranscript(note: notification)
        }
    }
    
    private func downloadedTranscript(note: NSNotification) {
        if let task = note.userInfo?[DL_COMPLETE_N_TASK] as? URLSessionDownloadTask, let taskURL = task.response?.url {
            let captionURL = getCaptionURL()
            if taskURL.absoluteString == captionURL {
                getClosedCaptioningFile(atURL: captionURL)
            }
        }
    }
    
    private func getCaptionURL() -> String {
        var captionURL: String = ""
        if let ccSelectedLanguage = OEXInterface.getCCSelectedLanguage(), let url = video.summary?.transcripts?[ccSelectedLanguage] as? String, !ccSelectedLanguage.isEmpty, !url.isEmpty{
            captionURL = url
        }
        else if let url = video.summary?.transcripts?.values.first as? String  {
            captionURL = url
        }
        return captionURL
    }
    
   private func getClosedCaptioningFile(atURL URLString: String?) {
        if let localFile: String = OEXFileUtility.filePath(forRequestKey: URLString) {
            var transcriptString = ""
            // File to string
            if FileManager.default.fileExists(atPath: localFile) {
                // File to string
                do {
                    let transcript = try String(contentsOfFile: localFile, encoding: .utf8)
                    transcriptString = transcript.replacingOccurrences(of: "\r", with:"\n")
                    transcriptParser.parse(subTitlesString: transcriptString, completion: { (success, error) in
                        transcripts = transcriptParser.transcripts
                        delegate?.transcriptsLoaded(manager: self, transcripts: transcripts)
                    })
                }
                catch _ {}
            }
            else {
                environment.interface?.download(withRequest: URLString, forceUpdate: false)
            }
        }
    }
    
    func transcript(at time: TimeInterval) -> String {
        let filteredSubTitles = transcripts.filter { return time > $0.start && time < $0.end }
        return filteredSubTitles.first?.text ?? ""
    }
}
