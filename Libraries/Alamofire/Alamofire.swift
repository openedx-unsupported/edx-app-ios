// Alamofire.swift
//
// Copyright (c) 2014–2015 Alamofire (http://alamofire.org)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

/// Alamofire errors
public let AlamofireErrorDomain = "com.alamofire.error"

/**
    HTTP method definitions.

    See http://tools.ietf.org/html/rfc7231#section-4.3
*/
public enum Method: String {
    case OPTIONS = "OPTIONS"
    case GET = "GET"
    case HEAD = "HEAD"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
    case TRACE = "TRACE"
    case CONNECT = "CONNECT"
}

/**
    Used to specify the way in which a set of parameters are applied to a URL request.
*/
public enum ParameterEncoding {
    /**
        A query string to be set as or appended to any existing URL query for `GET`, `HEAD`, and `DELETE` requests, or set as the body for requests with any other HTTP method. The `Content-Type` HTTP header field of an encoded request with HTTP body is set to `application/x-www-form-urlencoded`. Since there is no published specification for how to encode collection types, the convention of appending `[]` to the key for array values (`foo[]=1&foo[]=2`), and appending the key surrounded by square brackets for nested dictionary values (`foo[bar]=baz`).
    */
    case url

    /**
        Uses `NSJSONSerialization` to create a JSON representation of the parameters object, which is set as the body of the request. The `Content-Type` HTTP header field of an encoded request is set to `application/json`.
    */
    case json

    /**
        Uses `NSPropertyListSerialization` to create a plist representation of the parameters object, according to the associated format and write options values, which is set as the body of the request. The `Content-Type` HTTP header field of an encoded request is set to `application/x-plist`.
    */
    case propertyList(PropertyListSerialization.PropertyListFormat, PropertyListSerialization.WriteOptions)

    /**
        Uses the associated closure value to construct a new request given an existing request and parameters.
    */
    case custom((URLRequestConvertible, [String: AnyObject]?) -> (Foundation.URLRequest, NSError?))

    /**
        Creates a URL request by encoding parameters and applying them onto an existing request.

        :param: URLRequest The request to have parameters applied
        :param: parameters The parameters to apply

        :returns: A tuple containing the constructed request and the error that occurred during parameter encoding, if any.
    */
    public func encode(_ urlRequest: URLRequestConvertible, parameters: [String: Any]?) -> (Foundation.URLRequest, NSError?) {
        if parameters == nil {
            return (urlRequest.urlRequest, nil)
        }

        var mutableURLRequest: NSMutableURLRequest! = (urlRequest.urlRequest as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        var error: NSError? = nil

        switch self {
        case .url:
            func query(_ parameters: [String: AnyObject]) -> String {
                var components: [(String, String)] = []
                for key in parameters.keys.sorted(by: <) {
                    let value: AnyObject! = parameters[key]
                    components += self.queryComponents(key, value)
                }

                return components.map{"\($0)=\($1)"}.joined(separator: "&")
            }

            func encodesParametersInURL(_ method: Method) -> Bool {
                switch method {
                case .GET, .HEAD, .DELETE:
                    return true
                default:
                    return false
                }
            }

            let method = Method(rawValue: mutableURLRequest.httpMethod)
            if method != nil && encodesParametersInURL(method!) {
                if var URLComponents = URLComponents(url: mutableURLRequest.url!, resolvingAgainstBaseURL: false) {
                    URLComponents.percentEncodedQuery = (URLComponents.percentEncodedQuery != nil ? URLComponents.percentEncodedQuery! + "&" : "") + query(parameters! as [String : AnyObject])
                    mutableURLRequest.url = URLComponents.url
                }
            } else {
                if mutableURLRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                    mutableURLRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                }

                mutableURLRequest.httpBody = query(parameters! as [String : AnyObject]).data(using: String.Encoding.utf8, allowLossyConversion: false)
            }
        case .json:
            let options = JSONSerialization.WritingOptions()
            do {
                let data = try JSONSerialization.data(withJSONObject: parameters!, options: options)
                mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                mutableURLRequest.httpBody = data
            }
            catch let e as NSError {
                error = e
            }
        case .propertyList(let (format, options)):
            do {
                let data = try PropertyListSerialization.data(fromPropertyList: parameters!, format: format, options: options)
                mutableURLRequest.setValue("application/x-plist", forHTTPHeaderField: "Content-Type")
                mutableURLRequest.httpBody = data
            }
            catch let e as NSError {
                error = e
            }
        case .custom(let closure):
            return closure(mutableURLRequest as! URLRequestConvertible, parameters as [String : AnyObject]?)
        }

        return (mutableURLRequest as URLRequest, error)
    }

    func queryComponents(_ key: String, _ value: AnyObject) -> [(String, String)] {
        var components: [(String, String)] = []
        if let dictionary = value as? [String: AnyObject] {
            for (nestedKey, value) in dictionary {
                components += queryComponents("\(key)[\(nestedKey)]", value)
            }
        } else if let array = value as? [AnyObject] {
            for value in array {
                components += queryComponents("\(key)[]", value)
            }
        } else {
            components.append(contentsOf: [(escape(key), escape("\(value)"))])
        }

        return components
    }

    func escape(_ string: String) -> String {
        let legalURLCharactersToBeEscaped: CFString = ":&=;+!@#$()',*" as CFString
        return CFURLCreateStringByAddingPercentEscapes(nil, string as CFString!, nil, legalURLCharactersToBeEscaped, CFStringBuiltInEncodings.UTF8.rawValue) as String
    }
}

// MARK: - URLStringConvertible

/**
    Types adopting the `URLStringConvertible` protocol can be used to construct URL strings, which are then used to construct URL requests.
*/
public protocol URLStringConvertible {
    /// The URL string.
    var URLString: String { get }
}

extension String: URLStringConvertible {
    public var URLString: String {
        return self
    }
}

extension URL: URLStringConvertible {
    public var URLString: String {
        return absoluteString
    }
}

extension URLComponents: URLStringConvertible {
    public var URLString: String {
        return url!.URLString
    }
}

extension Foundation.URLRequest: URLStringConvertible {
    public var URLString: String {
        return url!.URLString
    }
}

// MARK: - URLRequestConvertible

/**
    Types adopting the `URLRequestConvertible` protocol can be used to construct URL requests.
*/
public protocol URLRequestConvertible {
    /// The URL request.
    var urlRequest: Foundation.URLRequest { get }
}

extension Foundation.URLRequest: URLRequestConvertible {
    public var urlRequest: Foundation.URLRequest {
        return self
    }
}

// MARK: -

/**
    Responsible for creating and managing `Request` objects, as well as their underlying `NSURLSession`.

    When finished with a manager, be sure to call either `session.finishTasksAndInvalidate()` or `session.invalidateAndCancel()` before deinitialization.
*/
open class Manager {

    /**
        A shared instance of `Manager`, used by top-level Alamofire request methods, and suitable for use directly for any ad hoc requests.
    */
    open static let sharedInstance: Manager = {
        let configuration: URLSessionConfiguration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = Manager.defaultHTTPHeaders

        return Manager(configuration: configuration)
    }()

    /**
        Creates default values for the "Accept-Encoding", "Accept-Language" and "User-Agent" headers.

        :returns: The default header values.
    */
    open static let defaultHTTPHeaders: [String: String] = {
        // Accept-Encoding HTTP Header; see http://tools.ietf.org/html/rfc7230#section-4.2.3
        let acceptEncoding: String = "gzip;q=1.0,compress;q=0.5"

        // Accept-Language HTTP Header; see http://tools.ietf.org/html/rfc7231#section-5.3.5
        let acceptLanguage: String = {
            var components: [String] = []
            for (index, languageCode) in Locale.preferredLanguages.enumerated() {
                let q = 1.0 - (Double(index) * 0.1)
                components.append("\(languageCode);q=\(q)")
                if q <= 0.5 {
                    break
                }
            }

            return components.joined(separator: ",")
        }()

        // User-Agent Header; see http://tools.ietf.org/html/rfc7231#section-5.5.3
        let userAgent: String = {
            if let info = Bundle.main.infoDictionary {
                let executable: AnyObject = info[kCFBundleExecutableKey as String] as AnyObject? ?? "Unknown" as AnyObject
                let bundle: AnyObject = info[kCFBundleIdentifierKey as String] as AnyObject? ?? "Unknown" as AnyObject
                let version: AnyObject = info[kCFBundleVersionKey as String] as AnyObject? ?? "Unknown" as AnyObject
                let os: AnyObject = ProcessInfo.processInfo.operatingSystemVersionString as AnyObject

                var mutableUserAgent = NSMutableString(string: "\(executable)/\(bundle) (\(version); OS \(os))") as CFMutableString
                let transform = NSString(string: "Any-Latin; Latin-ASCII; [:^ASCII:] Remove") as CFString
                if CFStringTransform(mutableUserAgent, nil, transform, false) == true {
                    return mutableUserAgent as String
                }
            }

            return "Alamofire"
        }()

        return ["Accept-Encoding": acceptEncoding,
                "Accept-Language": acceptLanguage,
                "User-Agent": userAgent]
    }()

    fileprivate let queue = DispatchQueue(label: "", attributes: [])

    /// The underlying session.
    open let session: URLSession

    /// The session delegate handling all the task and session delegate callbacks.
    open let delegate: SessionDelegate

    /// Whether to start requests immediately after being constructed. `true` by default.
    open var startRequestsImmediately: Bool = true

    /// The background completion handler closure provided by the UIApplicationDelegate `application:handleEventsForBackgroundURLSession:completionHandler:` method. By setting the background completion handler, the SessionDelegate `sessionDidFinishEventsForBackgroundURLSession` closure implementation will automatically call the handler. If you need to handle your own events before the handler is called, then you need to override the SessionDelegate `sessionDidFinishEventsForBackgroundURLSession` and manually call the handler when finished. `nil` by default.
    open var backgroundCompletionHandler: (() -> Void)?

    /**
        :param: configuration The configuration used to construct the managed session.
    */
    required public init(configuration: URLSessionConfiguration = URLSessionConfiguration()) {
        self.delegate = SessionDelegate()
        self.session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)

        self.delegate.sessionDidFinishEventsForBackgroundURLSession = { [weak self] session in
            if let strongSelf = self {
                strongSelf.backgroundCompletionHandler?()
            }
        }
    }

    // MARK: -

    /**
        Creates a request for the specified method, URL string, parameters, and parameter encoding.

        :param: method The HTTP method.
        :param: URLString The URL string.
        :param: parameters The parameters. `nil` by default.
        :param: encoding The parameter encoding. `.URL` by default.

        :returns: The created request.
    */
    open func request(_ method: Method, _ URLString: URLStringConvertible, parameters: [String: AnyObject]? = nil, encoding: ParameterEncoding = .url) -> Request {
        return request(encoding.encode(URLRequest(method, URL: URLString), parameters: parameters).0)
    }


    /**
        Creates a request for the specified URL request.

        If `startRequestsImmediately` is `true`, the request will have `resume()` called before being returned.

        :param: URLRequest The URL request

        :returns: The created request.
    */
    open func request(_ URLRequest: URLRequestConvertible) -> Request {
        var dataTask: URLSessionDataTask?
        queue.sync {
            dataTask = self.session.dataTask(with: URLRequest.urlRequest)
        }

        let request = Request(session: session, task: dataTask!)
        delegate[request.delegate.task] = request.delegate

        if startRequestsImmediately {
            request.resume()
        }

        return request
    }

    /**
        Responsible for handling all delegate callbacks for the underlying session.
    */
    public final class SessionDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate {
        fileprivate var subdelegates: [Int: Request.TaskDelegate] = [:]
        fileprivate let subdelegateQueue = DispatchQueue(label: "", attributes: DispatchQueue.Attributes.concurrent)
        fileprivate subscript(task: URLSessionTask) -> Request.TaskDelegate? {
            get {
                var subdelegate: Request.TaskDelegate?
                subdelegateQueue.sync {
                    subdelegate = self.subdelegates[task.taskIdentifier]
                }

                return subdelegate
            }

            set {
                subdelegateQueue.async(flags: .barrier, execute: {
                    self.subdelegates[task.taskIdentifier] = newValue
                }) 
            }
        }

        // MARK: NSURLSessionDelegate

        /// NSURLSessionDelegate override closure for `URLSession:didBecomeInvalidWithError:` method.
        public var sessionDidBecomeInvalidWithError: ((Foundation.URLSession?, NSError?) -> Void)?

        /// NSURLSessionDelegate override closure for `URLSession:didReceiveChallenge:completionHandler:` method.
        public var sessionDidReceiveChallenge: ((Foundation.URLSession?, URLAuthenticationChallenge) -> (Foundation.URLSession.AuthChallengeDisposition, URLCredential?))?

        /// NSURLSessionDelegate override closure for `URLSession:didFinishEventsForBackgroundURLSession:` method.
        public var sessionDidFinishEventsForBackgroundURLSession: ((Foundation.URLSession?) -> Void)?

        public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
            sessionDidBecomeInvalidWithError?(session, error as NSError?)
        }

        public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            if sessionDidReceiveChallenge != nil {
                let result = sessionDidReceiveChallenge!(session, challenge)
                completionHandler(result.0, result.1)
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        }

        public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
            sessionDidFinishEventsForBackgroundURLSession?(session)
        }

        // MARK: NSURLSessionTaskDelegate

        /// Overrides default behavior for NSURLSessionTaskDelegate method `URLSession:willPerformHTTPRedirection:newRequest:completionHandler:`.
        public var taskWillPerformHTTPRedirection: ((Foundation.URLSession?, URLSessionTask?, HTTPURLResponse?, Foundation.URLRequest?) -> (Foundation.URLRequest?))?

        /// Overrides default behavior for NSURLSessionTaskDelegate method `URLSession:willPerformHTTPRedirection:newRequest:completionHandler:`.
        public var taskDidReceiveChallenge: ((Foundation.URLSession?, URLSessionTask?, URLAuthenticationChallenge) -> (Foundation.URLSession.AuthChallengeDisposition, URLCredential?))?

        /// Overrides default behavior for NSURLSessionTaskDelegate method `URLSession:task:didCompleteWithError:`.
        public var taskNeedNewBodyStream: ((Foundation.URLSession?, URLSessionTask?) -> (InputStream?))?

        /// Overrides default behavior for NSURLSessionTaskDelegate method `URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:`.
        public var taskDidSendBodyData: ((Foundation.URLSession?, URLSessionTask?, Int64, Int64, Int64) -> Void)?

        /// Overrides default behavior for NSURLSessionTaskDelegate method `URLSession:task:didCompleteWithError:`.
        public var taskDidComplete: ((Foundation.URLSession?, URLSessionTask?, NSError?) -> Void)?

        public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            var redirectRequest = request

            if taskWillPerformHTTPRedirection != nil {
                redirectRequest = taskWillPerformHTTPRedirection!(session, task, response, request)!
            }

            completionHandler(redirectRequest)
        }

        public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            if taskDidReceiveChallenge != nil {
                let result = taskDidReceiveChallenge!(session, task, challenge)
                completionHandler(result.0, result.1)
            } else if let delegate = self[task] {
                delegate.urlSession(session, task: task, didReceive: challenge, completionHandler: completionHandler)
            } else {
                urlSession(session, didReceive: challenge, completionHandler: completionHandler)
            }
        }

        public func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: (@escaping (InputStream?) -> Void)) {
            if taskNeedNewBodyStream != nil {
                completionHandler(taskNeedNewBodyStream!(session, task))
            } else if let delegate = self[task] {
                delegate.urlSession(session, task: task, needNewBodyStream: completionHandler)
            }
        }

        public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
            if taskDidSendBodyData != nil {
                taskDidSendBodyData!(session, task, bytesSent, totalBytesSent, totalBytesExpectedToSend)
            } else if let delegate = self[task] as? Request.UploadTaskDelegate {
                delegate.URLSession(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
            }
        }

        public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            if let taskDidComplete = taskDidComplete {
                taskDidComplete(session, task, error as NSError?)
            } else if let delegate = self[task] {
                delegate.urlSession(session, task: task, didCompleteWithError: error)

                self[task] = nil
            }
        }

        // MARK: NSURLSessionDataDelegate

        /// Overrides default behavior for NSURLSessionDataDelegate method `URLSession:dataTask:didReceiveResponse:completionHandler:`.
        public var dataTaskDidReceiveResponse: ((Foundation.URLSession?, URLSessionDataTask?, URLResponse?) -> (Foundation.URLSession.ResponseDisposition))?

        /// Overrides default behavior for NSURLSessionDataDelegate method `URLSession:dataTask:didBecomeDownloadTask:`.
        public var dataTaskDidBecomeDownloadTask: ((Foundation.URLSession?, URLSessionDataTask?, URLSessionDownloadTask?) -> Void)?

        /// Overrides default behavior for NSURLSessionDataDelegate method `URLSession:dataTask:didReceiveData:`.
        public var dataTaskDidReceiveData: ((Foundation.URLSession?, URLSessionDataTask?, Data?) -> Void)?

        /// Overrides default behavior for NSURLSessionDataDelegate method `URLSession:dataTask:willCacheResponse:completionHandler:`.
        public var dataTaskWillCacheResponse: ((Foundation.URLSession?, URLSessionDataTask?, CachedURLResponse?) -> (CachedURLResponse))?

        public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: (@escaping (Foundation.URLSession.ResponseDisposition) -> Void)) {
            var disposition: Foundation.URLSession.ResponseDisposition = .allow

            if dataTaskDidReceiveResponse != nil {
                disposition = dataTaskDidReceiveResponse!(session, dataTask, response)
            }

            completionHandler(disposition)
        }

        public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
            if dataTaskDidBecomeDownloadTask != nil {
                dataTaskDidBecomeDownloadTask!(session, dataTask, downloadTask)
            } else {
                let downloadDelegate = Request.DownloadTaskDelegate(task: downloadTask)
                self[downloadTask] = downloadDelegate
            }
        }

        public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            if dataTaskDidReceiveData != nil {
                dataTaskDidReceiveData!(session, dataTask, data)
            } else if let delegate = self[dataTask] as? Request.DataTaskDelegate {
                delegate.urlSession(session, dataTask: dataTask, didReceive: data)
            }
        }

        public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: (@escaping (CachedURLResponse?) -> Void)) {
            if dataTaskWillCacheResponse != nil {
                completionHandler(dataTaskWillCacheResponse!(session, dataTask, proposedResponse))
            } else if let delegate = self[dataTask] as? Request.DataTaskDelegate {
                delegate.urlSession(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler)
            } else {
                completionHandler(proposedResponse)
            }
        }

        // MARK: NSURLSessionDownloadDelegate

        /// Overrides default behavior for NSURLSessionDownloadDelegate method `URLSession:downloadTask:didFinishDownloadingToURL:`.
        public var downloadTaskDidFinishDownloadingToURL: ((Foundation.URLSession?, URLSessionDownloadTask?, URL) -> (URL))?

        /// Overrides default behavior for NSURLSessionDownloadDelegate method `URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:`.
        public var downloadTaskDidWriteData: ((Foundation.URLSession?, URLSessionDownloadTask?, Int64, Int64, Int64) -> Void)?

        /// Overrides default behavior for NSURLSessionDownloadDelegate method `URLSession:downloadTask:didResumeAtOffset:expectedTotalBytes:`.
        public var downloadTaskDidResumeAtOffset: ((Foundation.URLSession?, URLSessionDownloadTask?, Int64, Int64) -> Void)?

        public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
            if downloadTaskDidFinishDownloadingToURL != nil {
               let _ =  downloadTaskDidFinishDownloadingToURL!(session, downloadTask, location)
            } else if let delegate = self[downloadTask] as? Request.DownloadTaskDelegate {
                delegate.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
            }
        }

        public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
            if downloadTaskDidWriteData != nil {
                downloadTaskDidWriteData!(session, downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
            } else if let delegate = self[downloadTask] as? Request.DownloadTaskDelegate {
                delegate.urlSession(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
            }
        }

        public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
            if downloadTaskDidResumeAtOffset != nil {
                downloadTaskDidResumeAtOffset!(session, downloadTask, fileOffset, expectedTotalBytes)
            } else if let delegate = self[downloadTask] as? Request.DownloadTaskDelegate {
                delegate.urlSession(session, downloadTask: downloadTask, didResumeAtOffset: fileOffset, expectedTotalBytes: expectedTotalBytes)
            }
        }

        // MARK: NSObject

        public override func responds(to selector: Selector) -> Bool {
            switch selector {
            case #selector(URLSessionDelegate.urlSession(_:didBecomeInvalidWithError:)):
                return (sessionDidBecomeInvalidWithError != nil)
            case #selector(URLSessionDelegate.urlSession(_:didReceive:completionHandler:)):
                return (sessionDidReceiveChallenge != nil)
            case #selector(URLSessionDelegate.urlSessionDidFinishEvents(forBackgroundURLSession:)):
                return (sessionDidFinishEventsForBackgroundURLSession != nil)
            case #selector(URLSessionTaskDelegate.urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)):
                return (taskWillPerformHTTPRedirection != nil)
            case #selector(URLSessionDataDelegate.urlSession(_:dataTask:didReceive:completionHandler:)):
                return (dataTaskDidReceiveResponse != nil)
            case #selector(URLSessionDataDelegate.urlSession(_:dataTask:willCacheResponse:completionHandler:)):
                return (dataTaskWillCacheResponse != nil)
            default:
                return type(of: self).instancesRespond(to: selector)
            }
        }
    }
}

// MARK: -

/**
    Responsible for sending a request and receiving the response and associated data from the server, as well as managing its underlying `NSURLSessionTask`.
*/
open class Request {
    fileprivate let delegate: TaskDelegate

    /// The underlying task.
    open var task: URLSessionTask { return delegate.task }

    /// The session belonging to the underlying task.
    open let session: URLSession

    /// The request sent or to be sent to the server.
    open var request: URLRequest { return task.originalRequest! }

    /// The response received from the server, if any.
    open var response: HTTPURLResponse? { return task.response as? HTTPURLResponse }

    /// The progress of the request lifecycle.
    open var progress: Progress { return delegate.progress }

    fileprivate init(session: URLSession, task: URLSessionTask) {
        self.session = session

        switch task {
        case is URLSessionUploadTask:
            self.delegate = UploadTaskDelegate(task: task)
        case is URLSessionDataTask:
            self.delegate = DataTaskDelegate(task: task)
        case is URLSessionDownloadTask:
            self.delegate = DownloadTaskDelegate(task: task)
        default:
            self.delegate = TaskDelegate(task: task)
        }
    }

    // MARK: Authentication

    /**
        Associates an HTTP Basic credential with the request.

        :param: user The user.
        :param: password The password.

        :returns: The request.
    */
    @discardableResult open func authenticate(user: String, password: String) -> Self {
        let credential = URLCredential(user: user, password: password, persistence: .forSession)

        return authenticate(usingCredential: credential)
    }

    /**
        Associates a specified credential with the request.

        :param: credential The credential.

        :returns: The request.
    */
    @discardableResult open func authenticate(usingCredential credential: URLCredential) -> Self {
        delegate.credential = credential

        return self
    }

    // MARK: Progress

    /**
        Sets a closure to be called periodically during the lifecycle of the request as data is written to or read from the server.

        - For uploads, the progress closure returns the bytes written, total bytes written, and total bytes expected to write.
        - For downloads, the progress closure returns the bytes read, total bytes read, and total bytes expected to write.

        :param: closure The code to be executed periodically during the lifecycle of the request.

        :returns: The request.
    */
    open func progress(_ closure: ((Int64, Int64, Int64) -> Void)? = nil) -> Self {
        if let uploadDelegate = delegate as? UploadTaskDelegate {
            uploadDelegate.uploadProgress = closure
        } else if let dataDelegate = delegate as? DataTaskDelegate {
            dataDelegate.dataProgress = closure
        } else if let downloadDelegate = delegate as? DownloadTaskDelegate {
            downloadDelegate.downloadProgress = closure
        }

        return self
    }

    // MARK: Response

    /**
        A closure used by response handlers that takes a request, response, and data and returns a serialized object and any error that occured in the process.
    */
    public typealias Serializer = (Foundation.URLRequest, HTTPURLResponse?, Data?) -> (AnyObject?, NSError?)

    /**
        Creates a response serializer that returns the associated data as-is.

        :returns: A data response serializer.
    */
    open class func responseDataSerializer() -> Serializer {
        return { (request, response, data) in
            return (data as AnyObject, nil)
        }
    }

    /**
        Adds a handler to be called once the request has finished.

        :param: completionHandler The code to be executed once the request has finished.

        :returns: The request.
    */
    @discardableResult open func response(_ completionHandler: @escaping (Foundation.URLRequest, HTTPURLResponse?, AnyObject?, NSError?) -> Void) -> Self {
        return response(serializer: Request.responseDataSerializer(), completionHandler:  completionHandler)
    }

    /**
        Adds a handler to be called once the request has finished.

        :param: queue The queue on which the completion handler is dispatched.
        :param: serializer The closure responsible for serializing the request, response, and data.
        :param: completionHandler The code to be executed once the request has finished.

        :returns: The request.
    */
    @discardableResult open func response(_ queue: DispatchQueue? = nil, serializer: @escaping Serializer, completionHandler: @escaping (Foundation.URLRequest, HTTPURLResponse?, AnyObject?, NSError?) -> Void) -> Self {
        delegate.queue.async {
            let (responseObject, serializationError) = serializer(self.request, self.response, self.delegate.data)

            (queue ?? DispatchQueue.main).async {
                completionHandler(self.request, self.response, responseObject, self.delegate.error ?? serializationError)
            }
        }

        return self
    }

    /**
        Suspends the request.
    */
    open func suspend() {
        task.suspend()
    }

    /**
        Resumes the request.
    */
    open func resume() {
        task.resume()
    }

    /**
        Cancels the request.
    */
    open func cancel() {
        if let downloadDelegate = delegate as? DownloadTaskDelegate {
            downloadDelegate.downloadTask.cancel { (data) in
                downloadDelegate.resumeData = data
            }
        } else {
            task.cancel()
        }
    }

    class TaskDelegate: NSObject, URLSessionTaskDelegate {
        let task: URLSessionTask
        let queue: DispatchQueue
        let progress: Progress

        var data: Data? { return nil }
        fileprivate(set) var error: NSError?

        var credential: URLCredential?

        var taskWillPerformHTTPRedirection: ((Foundation.URLSession?, URLSessionTask?, HTTPURLResponse?, Foundation.URLRequest?) -> (Foundation.URLRequest?))?
        var taskDidReceiveChallenge: ((Foundation.URLSession?, URLSessionTask?, URLAuthenticationChallenge) -> (Foundation.URLSession.AuthChallengeDisposition, URLCredential?))?
        var taskDidSendBodyData: ((Foundation.URLSession?, URLSessionTask?, Int64, Int64, Int64) -> Void)?
        var taskNeedNewBodyStream: ((Foundation.URLSession?, URLSessionTask?) -> (InputStream?))?

        init(task: URLSessionTask) {
            self.task = task
            self.progress = Progress(totalUnitCount: 0)
            self.queue = {
                let label: String = "com.alamofire.task-\(task.taskIdentifier)"
                let queue = DispatchQueue(label: label, attributes: [])

                queue.suspend()

                return queue
            }()
        }

        // MARK: NSURLSessionTaskDelegate

        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: (@escaping (Foundation.URLRequest?) -> Void)) {
            var redirectRequest = request
            if taskWillPerformHTTPRedirection != nil {
                redirectRequest = taskWillPerformHTTPRedirection!(session, task, response, request)!
            }

            completionHandler(redirectRequest)
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: (@escaping (Foundation.URLSession.AuthChallengeDisposition, URLCredential?) -> Void)) {
            var disposition: Foundation.URLSession.AuthChallengeDisposition = .performDefaultHandling
            var credential: URLCredential?

            if taskDidReceiveChallenge != nil {
                (disposition, credential) = taskDidReceiveChallenge!(session, task, challenge)
            } else {
                if challenge.previousFailureCount > 0 {
                    disposition = .cancelAuthenticationChallenge
                } else {
                    credential = self.credential ?? session.configuration.urlCredentialStorage?.defaultCredential(for: challenge.protectionSpace)
                    if credential != nil {
                        disposition = .useCredential
                    }
                }
            }

            completionHandler(disposition, credential)
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: (@escaping (InputStream?) -> Void)) {
            var bodyStream: InputStream?
            if taskNeedNewBodyStream != nil {
                bodyStream = taskNeedNewBodyStream!(session, task)
            }

            completionHandler(bodyStream)
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            if error != nil {
                self.error = error as NSError?
            }

            queue.resume()
        }
    }

    class DataTaskDelegate: TaskDelegate, URLSessionDataDelegate {
        var dataTask: URLSessionDataTask! { return task as! URLSessionDataTask }

        fileprivate var mutableData: NSMutableData
        override var data: Data? {
            return mutableData as Data
        }

        fileprivate var expectedContentLength: Int64?

        var dataTaskDidReceiveResponse: ((Foundation.URLSession?, URLSessionDataTask?, URLResponse?) -> (Foundation.URLSession.ResponseDisposition))?
        var dataTaskDidBecomeDownloadTask: ((Foundation.URLSession?, URLSessionDataTask?) -> Void)?
        var dataTaskDidReceiveData: ((Foundation.URLSession?, URLSessionDataTask?, Data?) -> Void)?
        var dataTaskWillCacheResponse: ((Foundation.URLSession?, URLSessionDataTask?, CachedURLResponse?) -> (CachedURLResponse))?
        var dataProgress: ((_ bytesReceived: Int64, _ totalBytesReceived: Int64, _ totalBytesExpectedToReceive: Int64) -> Void)?

        override init(task: URLSessionTask) {
            self.mutableData = NSMutableData()
            super.init(task: task)
        }

        // MARK: NSURLSessionDataDelegate

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: (@escaping (Foundation.URLSession.ResponseDisposition) -> Void)) {
            var disposition: Foundation.URLSession.ResponseDisposition = .allow

            expectedContentLength = response.expectedContentLength

            if dataTaskDidReceiveResponse != nil {
                disposition = dataTaskDidReceiveResponse!(session, dataTask, response)
            }

            completionHandler(disposition)
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
            dataTaskDidBecomeDownloadTask?(session, dataTask)
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            dataTaskDidReceiveData?(session, dataTask, data)

            mutableData.append(data)

            if let expectedContentLength = dataTask.response?.expectedContentLength {
                dataProgress?(Int64(data.count), Int64(mutableData.length), expectedContentLength)
            }
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
            var cachedResponse = proposedResponse

            if dataTaskWillCacheResponse != nil {
                cachedResponse = dataTaskWillCacheResponse!(session, dataTask, proposedResponse)
            }

            completionHandler(cachedResponse)
        }
    }
}

// MARK: - Validation

extension Request {

    /**
        A closure used to validate a request that takes a URL request and URL response, and returns whether the request was valid.
    */
    public typealias Validation = (Foundation.URLRequest, HTTPURLResponse) -> (Bool)

    /**
        Validates the request, using the specified closure.

        If validation fails, subsequent calls to response handlers will have an associated error.

        :param: validation A closure to validate the request.

        :returns: The request.
    */
    public func validate(_ validation: @escaping Validation) -> Self {
        delegate.queue.async {
            if self.response != nil && self.delegate.error == nil {
                if !validation(self.request, self.response!) {
                    self.delegate.error = NSError(domain: AlamofireErrorDomain, code: -1, userInfo: nil)
                }
            }
        }

        return self
    }

    // MARK: Status Code

    /**
        Validates that the response has a status code in the specified range.

        If validation fails, subsequent calls to response handlers will have an associated error.

        :param: range The range of acceptable status codes.

        :returns: The request.
    */
    public func validate<S : Sequence>(statusCode acceptableStatusCode: S) -> Self where S.Iterator.Element == Int {
        return validate { (_, response) in
            return acceptableStatusCode.contains(response.statusCode)
        }
    }

    // MARK: Content-Type

    fileprivate struct MIMEType {
        let type: String
        let subtype: String

        init?(_ string: String) {
            let components = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).substring(to: string.range(of: ";")?.upperBound ?? string.endIndex).components(separatedBy: "/")

            if let type = components.first,
                    let subtype = components.last
            {
                self.type = type
                self.subtype = subtype
            } else {
                return nil
            }
        }

        func matches(_ MIME: MIMEType) -> Bool {
            switch (type, subtype) {
            case (MIME.type, MIME.subtype), (MIME.type, "*"), ("*", MIME.subtype), ("*", "*"):
                return true
            default:
                return false
            }
        }
    }

    /**
        Validates that the response has a content type in the specified array.

        If validation fails, subsequent calls to response handlers will have an associated error.

        :param: contentType The acceptable content types, which may specify wildcard types and/or subtypes.

        :returns: The request.
    */
    public func validate<S : Sequence>(contentType acceptableContentTypes: S) -> Self where S.Iterator.Element == String {
        return validate {(_, response) in
            if let responseContentType = response.mimeType,
                    let responseMIMEType = MIMEType(responseContentType)
            {
                for contentType in acceptableContentTypes {
                    if let acceptableMIMEType = MIMEType(contentType), acceptableMIMEType.matches(responseMIMEType)
                    {
                        return true
                    }
                }
            }

            return false
        }
    }

    // MARK: Automatic

    /**
        Validates that the response has a status code in the default acceptable range of 200...299, and that the content type matches any specified in the Accept HTTP header field.

        If validation fails, subsequent calls to response handlers will have an associated error.

        :returns: The request.
    */
    public func validate() -> Self {
        let acceptableStatusCodes: CountableRange<Int> = 200..<300
        let acceptableContentTypes: [String] = {
            if let accept = self.request.value(forHTTPHeaderField: "Accept") {
                return accept.components(separatedBy: ",")
            }

            return ["*/*"]
        }()

        return validate(statusCode: acceptableStatusCodes).validate(contentType: acceptableContentTypes)
    }
}

// MARK: - Upload

extension Manager {
    fileprivate enum Uploadable {
        case data(Foundation.URLRequest, Foundation.Data)
        case file(Foundation.URLRequest, URL)
        case stream(Foundation.URLRequest, InputStream)
    }

    fileprivate func upload(_ uploadable: Uploadable) -> Request {
        var uploadTask: URLSessionUploadTask!
        var HTTPBodyStream: InputStream?

        switch uploadable {
        case .data(let request, let data):
            queue.sync {
                uploadTask = self.session.uploadTask(with: request, from: data)
            }
        case .file(let request, let fileURL):
            queue.sync {
                uploadTask = self.session.uploadTask(with: request, fromFile: fileURL)
            }
        case .stream(let request, let stream):
            queue.sync {
                uploadTask = self.session.uploadTask(withStreamedRequest: request)
            }
            HTTPBodyStream = stream
        }

        let request = Request(session: session, task: uploadTask)
        if HTTPBodyStream != nil {
            request.delegate.taskNeedNewBodyStream = { _, _ in
                return HTTPBodyStream
            }
        }
        delegate[request.delegate.task] = request.delegate

        if startRequestsImmediately {
            request.resume()
        }

        return request
    }

    // MARK: File

    /**
        Creates a request for uploading a file to the specified URL request.

        If `startRequestsImmediately` is `true`, the request will have `resume()` called before being returned.

        :param: URLRequest The URL request
        :param: file The file to upload

        :returns: The created upload request.
    */
    public func upload(_ urlRequest: URLRequestConvertible, file: URL) -> Request {
        return upload(.file(urlRequest.urlRequest, file))
    }

    /**
        Creates a request for uploading a file to the specified URL request.

        If `startRequestsImmediately` is `true`, the request will have `resume()` called before being returned.

        :param: method The HTTP method.
        :param: URLString The URL string.
        :param: file The file to upload

        :returns: The created upload request.
    */
    public func upload(_ method: Method, _ URLString: URLStringConvertible, file: URL) -> Request {
        return upload(URLRequest(method, URL: URLString), file: file)
    }

    // MARK: Data

    /**
        Creates a request for uploading data to the specified URL request.

        If `startRequestsImmediately` is `true`, the request will have `resume()` called before being returned.

        :param: URLRequest The URL request
        :param: data The data to upload

        :returns: The created upload request.
    */
    public func upload(_ urlRequest: URLRequestConvertible, data: Data) -> Request {
        return upload(.data(urlRequest.urlRequest, data))
    }

    /**
        Creates a request for uploading data to the specified URL request.

        If `startRequestsImmediately` is `true`, the request will have `resume()` called before being returned.

        :param: method The HTTP method.
        :param: URLString The URL string.
        :param: data The data to upload

        :returns: The created upload request.
    */
    public func upload(_ method: Method, _ URLString: URLStringConvertible, data: Data) -> Request {
        return upload(URLRequest(method, URL: URLString), data: data)
    }

    // MARK: Stream

    /**
        Creates a request for uploading a stream to the specified URL request.

        If `startRequestsImmediately` is `true`, the request will have `resume()` called before being returned.

        :param: URLRequest The URL request
        :param: stream The stream to upload

        :returns: The created upload request.
    */
    public func upload(_ urlRequest: URLRequestConvertible, stream: InputStream) -> Request {
        return upload(.stream(urlRequest.urlRequest, stream))
    }

    /**
        Creates a request for uploading a stream to the specified URL request.

        If `startRequestsImmediately` is `true`, the request will have `resume()` called before being returned.

        :param: method The HTTP method.
        :param: URLString The URL string.
        :param: stream The stream to upload.

        :returns: The created upload request.
    */
    public func upload(_ method: Method, _ URLString: URLStringConvertible, stream: InputStream) -> Request {
        return upload(URLRequest(method, URL: URLString), stream: stream)
    }
}

extension Request {
    class UploadTaskDelegate: DataTaskDelegate {
        var uploadTask: URLSessionUploadTask! { return task as! URLSessionUploadTask }
        var uploadProgress: ((Int64, Int64, Int64) -> Void)!

        // MARK: NSURLSessionTaskDelegate

        func URLSession(_ session: Foundation.URLSession!, task: URLSessionTask!, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
            progress.totalUnitCount = totalBytesExpectedToSend
            progress.completedUnitCount = totalBytesSent

            uploadProgress?(bytesSent, totalBytesSent, totalBytesExpectedToSend)
        }
    }
}

// MARK: - Download

extension Manager {
    fileprivate enum Downloadable {
        case request(Foundation.URLRequest)
        case resumeData(Data)
    }

    fileprivate func download(_ downloadable: Downloadable, destination: @escaping Request.DownloadFileDestination) -> Request {
        var downloadTask: URLSessionDownloadTask!

        switch downloadable {
        case .request(let request):
            queue.sync {
                downloadTask = self.session.downloadTask(with: request)
            }
        case .resumeData(let resumeData):
            queue.sync {
                downloadTask = self.session.downloadTask(withResumeData: resumeData)
            }
        }

        let request = Request(session: session, task: downloadTask)
        if let downloadDelegate = request.delegate as? Request.DownloadTaskDelegate {
            downloadDelegate.downloadTaskDidFinishDownloadingToURL = { (session, downloadTask, URL) in
                return destination(URL, downloadTask?.response as! HTTPURLResponse)
            }
        }
        delegate[request.delegate.task] = request.delegate

        if startRequestsImmediately {
            request.resume()
        }

        return request
    }

    // MARK: Request

    /**
        Creates a download request using the shared manager instance for the specified method and URL string.

        :param: method The HTTP method.
        :param: URLString The URL string.
        :param: destination The closure used to determine the destination of the downloaded file.

        :returns: The created download request.
    */
    public func download(_ method: Method, _ URLString: URLStringConvertible, destination: @escaping Request.DownloadFileDestination) -> Request {
        return download(URLRequest(method, URL: URLString), destination: destination)
    }

    /**
        Creates a request for downloading from the specified URL request.

        If `startRequestsImmediately` is `true`, the request will have `resume()` called before being returned.

        :param: URLRequest The URL request
        :param: destination The closure used to determine the destination of the downloaded file.

        :returns: The created download request.
    */
    public func download(_ urlRequest: URLRequestConvertible, destination: @escaping Request.DownloadFileDestination) -> Request {
        return download(.request(urlRequest.urlRequest), destination: destination)
    }

    // MARK: Resume Data

    /**
        Creates a request for downloading from the resume data produced from a previous request cancellation.

        If `startRequestsImmediately` is `true`, the request will have `resume()` called before being returned.

        :param: resumeData The resume data. This is an opaque data blob produced by `NSURLSessionDownloadTask` when a task is cancelled. See `NSURLSession -downloadTaskWithResumeData:` for additional information.
        :param: destination The closure used to determine the destination of the downloaded file.

        :returns: The created download request.
    */
    public func download(_ resumeData: Data, destination: @escaping Request.DownloadFileDestination) -> Request {
        //return download(.resumeData(resumeData), destination: destination)
        return download(.resumeData(resumeData), destination: destination)
    }
}

extension Request {
    /**
        A closure executed once a request has successfully completed in order to determine where to move the temporary file written to during the download process. The closure takes two arguments: the temporary file URL and the URL response, and returns a single argument: the file URL where the temporary file should be moved.
    */
    public typealias DownloadFileDestination = (URL, HTTPURLResponse) -> (URL)

    /**
        Creates a download file destination closure which uses the default file manager to move the temporary file to a file URL in the first available directory with the specified search path directory and search path domain mask.

        :param: directory The search path directory. `.DocumentDirectory` by default.
        :param: domain The search path domain mask. `.UserDomainMask` by default.

        :returns: A download file destination closure.
    */
    public class func suggestedDownloadDestination(_ directory: FileManager.SearchPathDirectory = .documentDirectory, domain: FileManager.SearchPathDomainMask = .userDomainMask) -> DownloadFileDestination {

        return { (temporaryURL, response) -> (URL) in
            let directoryURLs = FileManager.default.urls(for: directory, in: domain)
            if directoryURLs.count > 0 {
                let directoryURL = directoryURLs[0]
                return directoryURL.appendingPathComponent(response.suggestedFilename!)
            }

            return temporaryURL
        }
    }

    class DownloadTaskDelegate: TaskDelegate, URLSessionDownloadDelegate {
        var downloadTask: URLSessionDownloadTask! { return task as! URLSessionDownloadTask }
        var downloadProgress: ((Int64, Int64, Int64) -> Void)?

        var resumeData: Data?
        override var data: Data? { return resumeData }

        var downloadTaskDidFinishDownloadingToURL: ((Foundation.URLSession?, URLSessionDownloadTask?, URL) -> (URL))?
        var downloadTaskDidWriteData: ((Foundation.URLSession?, URLSessionDownloadTask?, Int64, Int64, Int64) -> Void)?
        var downloadTaskDidResumeAtOffset: ((Foundation.URLSession?, URLSessionDownloadTask?, Int64, Int64) -> Void)?

        // MARK: NSURLSessionDownloadDelegate

        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
            if downloadTaskDidFinishDownloadingToURL != nil {
                let destination = downloadTaskDidFinishDownloadingToURL!(session, downloadTask, location)

                do {
                    try FileManager.default.moveItem(at: location, to: destination)
                }
                catch let e as NSError {
                    error = e
                }
            }
        }

        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
            progress.totalUnitCount = totalBytesExpectedToWrite
            progress.completedUnitCount = totalBytesWritten

            downloadTaskDidWriteData?(session, downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)

            downloadProgress?(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
        }

        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
            progress.totalUnitCount = expectedTotalBytes
            progress.completedUnitCount = fileOffset

            downloadTaskDidResumeAtOffset?(session, downloadTask, fileOffset, expectedTotalBytes)
        }
    }
}

// MARK: - Printable

extension Request: CustomStringConvertible {
    /// The textual representation used when written to an `OutputStreamType`, which includes the HTTP method and URL, as well as the response status code if a response has been received.
    public var description: String {
        var components: [String] = []
        if request.httpMethod != nil {
            components.append(request.httpMethod!)
        }

        components.append(request.url!.absoluteString)

        if response != nil {
            components.append("(\(response!.statusCode))")
        }

        return components.joined(separator: " ")
    }
}

extension Request : CustomDebugStringConvertible {
    func cURLRepresentation() -> String {
        var components: [String] = ["$ curl -i"]

        let URL = request.url

        if request.httpMethod != nil && request.httpMethod != "GET" {
            components.append("-X \(request.httpMethod!)")
        }

        if let credentialStorage = self.session.configuration.urlCredentialStorage {
            let protectionSpace = URLProtectionSpace(host: URL!.host!, port: (URL! as NSURL).port?.intValue ?? 0, protocol: URL!.scheme, realm: URL!.host!, authenticationMethod: NSURLAuthenticationMethodHTTPBasic)
            if let credentials = credentialStorage.credentials(for: protectionSpace)?.values {
                for credential in credentials {
                    components.append("-u \(credential.user!):\(credential.password!)")
                }
            } else {
                if let credential = delegate.credential {
                    components.append("-u \(credential.user!):\(credential.password!)")
                }
            }
        }

        // Temporarily disabled on OS X due to build failure for CocoaPods
        // See https://github.com/CocoaPods/swift/issues/24
        #if !os(OSX)
        if let cookieStorage = session.configuration.httpCookieStorage,
               let cookies = cookieStorage.cookies(for: URL!), !cookies.isEmpty
        {
            let string = cookies.reduce(""){ $0 + "\($1.name)=\($1.value );" }
            components.append("-b \"\(string.substring(to: string.index(before: string.endIndex)))\"")
        }
        #endif

        if request.allHTTPHeaderFields != nil {
            for (field, value) in request.allHTTPHeaderFields! {
                switch field {
                case "Cookie":
                    continue
                default:
                    components.append("-H \"\(field): \(value)\"")
                }
            }
        }

        if session.configuration.httpAdditionalHeaders != nil {
            for (field, value) in session.configuration.httpAdditionalHeaders! {
                switch field {
                case AnyHashable("Cookie"):
                    continue
                default:
                    components.append("-H \"\(field): \(value)\"")
                }
            }
        }

        if let HTTPBody = request.httpBody,
               let escapedBody = NSString(data: HTTPBody, encoding: String.Encoding.utf8.rawValue)?.replacingOccurrences(of: "\"", with: "\\\"")
        {
            components.append("-d \"\(escapedBody)\"")
        }

        components.append("\"\(URL!.absoluteString)\"")

        return components.joined(separator: " \\\n\t")
    }

    /// The textual representation used when written to an `OutputStreamType`, in the form of a cURL command.
    public var debugDescription: String {
        return cURLRepresentation()
    }
}

// MARK: - Response Serializers

// MARK: String

extension Request {
    /**
        Creates a response serializer that returns a string initialized from the response data with the specified string encoding.

        :param: encoding The string encoding. If `nil`, the string encoding will be determined from the server response, falling back to the default HTTP default character set, ISO-8859-1.

        :returns: A string response serializer.
    */
    public class func stringResponseSerializer(_ encoding: String.Encoding? = nil) -> Serializer {
        var encoding = encoding
        return { (_, response, data) in
            if data == nil || data?.count == 0 {
                return (nil, nil)
            }

            if encoding == nil {
                if let encodingName = response?.textEncodingName {
                    encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding(encodingName as CFString?)))
                }
            }

            let string = NSString(data: data!, encoding: encoding.map { $0.rawValue } ?? String.Encoding.isoLatin1.rawValue)

            return (string, nil)
        }
    }

    /**
        Adds a handler to be called once the request has finished.

        :param: encoding The string encoding. If `nil`, the string encoding will be determined from the server response, falling back to the default HTTP default character set, ISO-8859-1.
        :param: completionHandler A closure to be executed once the request has finished. The closure takes 4 arguments: the URL request, the URL response, if one was received, the string, if one could be created from the URL response and data, and any error produced while creating the string.

        :returns: The request.
    */
    public func responseString(_ encoding: String.Encoding? = nil, completionHandler: @escaping (Foundation.URLRequest, HTTPURLResponse?, String?, NSError?) -> Void) -> Self  {
        return response(serializer: Request.stringResponseSerializer(encoding), completionHandler: { request, response, string, error in
            completionHandler(request, response, string as? String, error)
        })
    }
}

// MARK: JSON

extension Request {
    /**
        Creates a response serializer that returns a JSON object constructed from the response data using `NSJSONSerialization` with the specified reading options.

        :param: options The JSON serialization reading options. `.AllowFragments` by default.

        :returns: A JSON object response serializer.
    */
    public class func JSONResponseSerializer(_ options: JSONSerialization.ReadingOptions = .allowFragments) -> Serializer {
        return { (request, response, data) in
            if data == nil || data?.count == 0 {
                return (nil, nil)
            }

            do {
                let JSON = try JSONSerialization.jsonObject(with: data!, options: options)
                return (JSON as AnyObject, nil)
            }
            catch let error as NSError {
                return (nil, error)
            }
        }
    }

    /**
        Adds a handler to be called once the request has finished.

        :param: options The JSON serialization reading options. `.AllowFragments` by default.
        :param: completionHandler A closure to be executed once the request has finished. The closure takes 4 arguments: the URL request, the URL response, if one was received, the JSON object, if one could be created from the URL response and data, and any error produced while creating the JSON object.

        :returns: The request.
    */
    public func responseJSON(_ options: JSONSerialization.ReadingOptions = .allowFragments, completionHandler: @escaping (Foundation.URLRequest, HTTPURLResponse?, AnyObject?, NSError?) -> Void) -> Self {
        return response(serializer: Request.JSONResponseSerializer(options), completionHandler: { (request, response, JSON, error) in
            completionHandler(request, response, JSON, error)
        })
    }
}

// MARK: Property List

extension Request {
    /**
        Creates a response serializer that returns an object constructed from the response data using `NSPropertyListSerialization` with the specified reading options.

        :param: options The property list reading options. `0` by default.

        :returns: A property list object response serializer.
    */
    public class func propertyListResponseSerializer(_ options: PropertyListSerialization.ReadOptions = PropertyListSerialization.ReadOptions()) -> Serializer {
        return { (request, response, data) in
            if data == nil || data?.count == 0 {
                return (nil, nil)
            }

            do {
                let plist: AnyObject? = try PropertyListSerialization.propertyList(from: data!, options: options, format: nil) as AnyObject?
                return (plist, nil)
            }
            catch let error as NSError {
                return (nil, error)
            }
        }
    }

    /**
        Adds a handler to be called once the request has finished.

        :param: options The property list reading options. `0` by default.
        :param: completionHandler A closure to be executed once the request has finished. The closure takes 4 arguments: the URL request, the URL response, if one was received, the property list, if one could be created from the URL response and data, and any error produced while creating the property list.

        :returns: The request.
    */
    public func responsePropertyList(_ options: PropertyListSerialization.ReadOptions = PropertyListSerialization.ReadOptions(), completionHandler: @escaping (Foundation.URLRequest, HTTPURLResponse?, AnyObject?, NSError?) -> Void) -> Self {
        return response(serializer: Request.propertyListResponseSerializer(options), completionHandler: { (request, response, plist, error) in
            completionHandler(request, response, plist, error)
        })
    }
}

// MARK: - Convenience -

private func URLRequest(_ method: Method, URL: URLStringConvertible) -> Foundation.URLRequest {
    let mutableURLRequest = NSMutableURLRequest(url: Foundation.URL(string: URL.URLString)!)
    mutableURLRequest.httpMethod = method.rawValue

    return mutableURLRequest as URLRequest
}

// MARK: - Request

/**
    Creates a request using the shared manager instance for the specified method, URL string, parameters, and parameter encoding.

    :param: method The HTTP method.
    :param: URLString The URL string.
    :param: parameters The parameters. `nil` by default.
    :param: encoding The parameter encoding. `.URL` by default.

    :returns: The created request.
*/
public func request(_ method: Method, URLString: URLStringConvertible, parameters: [String: AnyObject]? = nil, encoding: ParameterEncoding = .url) -> Request {
    return Manager.sharedInstance.request(method, URLString, parameters: parameters, encoding: encoding)
}

/**
    Creates a request using the shared manager instance for the specified URL request.

    If `startRequestsImmediately` is `true`, the request will have `resume()` called before being returned.

    :param: URLRequest The URL request

    :returns: The created request.
*/
public func request(_ urlRequest: URLRequestConvertible) -> Request {
    return Manager.sharedInstance.request(urlRequest.urlRequest)
}

// MARK: - Upload

// MARK: File

/**
    Creates an upload request using the shared manager instance for the specified method, URL string, and file.

    :param: method The HTTP method.
    :param: URLString The URL string.
    :param: file The file to upload.

    :returns: The created upload request.
*/
public func upload(_ method: Method, URLString: URLStringConvertible, file: URL) -> Request {
    return Manager.sharedInstance.upload(method, URLString, file: file)
}

/**
    Creates an upload request using the shared manager instance for the specified URL request and file.

    :param: URLRequest The URL request.
    :param: file The file to upload.

    :returns: The created upload request.
*/
public func upload(_ URLRequest: URLRequestConvertible, file: URL) -> Request {
    return Manager.sharedInstance.upload(URLRequest, file: file)
}

// MARK: Data

/**
    Creates an upload request using the shared manager instance for the specified method, URL string, and data.

    :param: method The HTTP method.
    :param: URLString The URL string.
    :param: data The data to upload.

    :returns: The created upload request.
*/
public func upload(_ method: Method, URLString: URLStringConvertible, data: Data) -> Request {
    return Manager.sharedInstance.upload(method, URLString, data: data)
}

/**
    Creates an upload request using the shared manager instance for the specified URL request and data.

    :param: URLRequest The URL request.
    :param: data The data to upload.

    :returns: The created upload request.
*/
public func upload(_ URLRequest: URLRequestConvertible, data: Data) -> Request {
    return Manager.sharedInstance.upload(URLRequest, data: data)
}

// MARK: Stream

/**
    Creates an upload request using the shared manager instance for the specified method, URL string, and stream.

    :param: method The HTTP method.
    :param: URLString The URL string.
    :param: stream The stream to upload.

    :returns: The created upload request.
*/
public func upload(_ method: Method, URLString: URLStringConvertible, stream: InputStream) -> Request {
    return Manager.sharedInstance.upload(method, URLString, stream: stream)
}

/**
    Creates an upload request using the shared manager instance for the specified URL request and stream.

    :param: URLRequest The URL request.
    :param: stream The stream to upload.

    :returns: The created upload request.
*/
public func upload(_ URLRequest: URLRequestConvertible, stream: InputStream) -> Request {
    return Manager.sharedInstance.upload(URLRequest, stream: stream)
}

// MARK: - Download

// MARK: URL Request

/**
    Creates a download request using the shared manager instance for the specified method and URL string.

    :param: method The HTTP method.
    :param: URLString The URL string.
    :param: destination The closure used to determine the destination of the downloaded file.

    :returns: The created download request.
*/
public func download(_ method: Method, URLString: URLStringConvertible, destination: @escaping Request.DownloadFileDestination) -> Request {
    return Manager.sharedInstance.download(method, URLString, destination: destination)
}

/**
    Creates a download request using the shared manager instance for the specified URL request.

    :param: URLRequest The URL request.
    :param: destination The closure used to determine the destination of the downloaded file.

    :returns: The created download request.
*/
public func download(_ URLRequest: URLRequestConvertible, destination: @escaping Request.DownloadFileDestination) -> Request {
    return Manager.sharedInstance.download(URLRequest, destination: destination)
}

// MARK: Resume Data

/**
    Creates a request using the shared manager instance for downloading from the resume data produced from a previous request cancellation.

    :param: resumeData The resume data. This is an opaque data blob produced by `NSURLSessionDownloadTask` when a task is cancelled. See `NSURLSession -downloadTaskWithResumeData:` for additional information.
    :param: destination The closure used to determine the destination of the downloaded file.

    :returns: The created download request.
*/
public func download(resumeData data: Data, destination: @escaping Request.DownloadFileDestination) -> Request {
    return Manager.sharedInstance.download(data, destination: destination)
}

extension URLSessionConfiguration {
    public func defaultHTTPHeaders() -> NSDictionary {
        return Manager.defaultHTTPHeaders as NSDictionary
    }
}
