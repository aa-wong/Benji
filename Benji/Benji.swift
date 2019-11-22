//
//  Benji.swift
//  Benji
//
//  Created by Aaron Wong on 2019-11-21.
//  Copyright © 2019 Aaron Wong. All rights reserved.
//

import Foundation

public enum BenjiRequestType {
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
    
    func string() -> String {
        switch self {
        case .GET:
            return "GET"
        case .POST:
            return "POST"
        case .PUT:
            return "PUT"
        case .PATCH:
            return "PATCH"
        case .DELETE:
            return "DELETE"
        }
    }
}

public class Benji: NSObject {
    
    private struct Static {
        static var instance: Benji?
    }
    
    // MARK: - SINGLETON PARAMETERS
    /// MARK: SHARED
    /// - returns: Benji Singleton Instance
    public class var shared: Benji {
        if Static.instance == nil {
            Static.instance = Benji()
        }
        return Static.instance!
    }
    
    /// MARK: DESTROY
    /// Deallocate Benji singleton instance
    /// - returns: Void
    public static func destroy() {
        Benji.Static.instance = nil
    }
    
    /// MARK: - Base URL
    /// Base url to be used as a reference for all HTTP calls
    public var baseURL : String?
    
    /// MARK: - Base Headers
    /// Base headers to be applied to all HTTP requests
    public var baseHeaders : [String : String]?

    
    // MARK: - DELELGATE VARIABLES
    public var fetchDelegate : BenjiFetchDelegate?
    public var uploadDelegate : BenjiUploadDelegate?
    public var downloadDelegate : BenjiDownloadDelegate?
        
    private let session : BenjiSession = BenjiSession()
    
    // MARK: - SESSION REQUESTERS
    /// MARK: GET
    /// Perform Simple Asychronous GET request
    ///
    /// - parameter url: url string or uri string to append to baseURL if set
    /// - parameter headers: Optional headers to be set or append to baseHeaders if set
    /// - returns: completion    /// - Returns error if exists, response if exists, data if exists
    public func GET(_ url:String,
                    headers: [String : String]?,
                    completion:@escaping (_ error: Error?, _ response: HTTPURLResponse?, _ data:Any?) -> Void) {
        
        return self.FETCH(.GET,
                          url: url,
                          headers: headers,
                          body: nil,
                          completion: completion)
    }
    
    /// MARK: POST
    /// Perform Simple Asychronous POST request
    ///
    /// - parameter url: url string or uri string to append to baseURL if set
    /// - parameter headers: Optional headers to be set or append to baseHeaders if set
    /// - parameter body: Object to parse and send as POST request
    /// - returns: completion    /// - Returns error if exists, response if exists, data if exists
    public func POST(_ url:String,
                     headers: [String : String]?,
                     body:Any,
                     completion: @escaping (_ error: Error?, _ response: HTTPURLResponse?, _ data:Any?) -> Void) {
        
        return self.FETCH(.POST,
                          url: url,
                          headers: headers,
                          body: body,
                          completion: completion)
    }
    
    /// MARK: PUT
    /// Perform Simple Asychronous PUT request
    ///
    /// - parameter url: url string or uri string to append to baseURL if set
    /// - parameter headers: Optional headers to be set or append to baseHeaders if set
    /// - parameter body: Object to parse and send as PUT request
    /// - returns: completion    /// - Returns error if exists, response if exists, data if exists
    public func PUT(_ url:String,
                    headers: [String : String]?,
                    body: Any,
                    completion: @escaping (_ error: Error?, _ response: HTTPURLResponse?, _ data:Any?) -> Void) {
        
        return self.FETCH(.PUT,
                          url: url,
                          headers: headers,
                          body: body,
                          completion: completion)
    }
    
    /// MARK: PATCH
    /// Perform Simple Asychronous PATCH request
    ///
    /// - parameter url: url string or uri string to append to baseURL if set
    /// - parameter headers: Optional headers to be set or append to baseHeaders if set
    /// - parameter body: Object to parse and send as PATCH request
    /// - returns: completion    /// - Returns error if exists, response if exists, data if exists
    public func PATCH(_ url:String,
                      headers: [String : String]?,
                      body:Any,
                      completion: @escaping (_ error: Error?, _ response: HTTPURLResponse?, _ data:Any?) -> Void) {
        
        return self.FETCH(.PATCH,
                          url: url,
                          headers: headers,
                          body: body,
                          completion: completion)
    }
    
    /// MARK: DELETE
    /// Perform Simple Asychronous DELETE request
    ///
    /// - parameter url: url string or uri string to append to baseURL if set
    /// - parameter headers: Optional headers to be set or append to baseHeaders if set
    /// - returns: completion    /// - Returns error if exists, response if exists, data if exists
    public func DELETE(_ url:String,
                       headers: [String : String]?,
                       completion: @escaping (_ error: Error?, _ response: HTTPURLResponse?, _ data:Any?) -> Void) {
        
        return self.FETCH(.DELETE,
                          url: url,
                          headers: headers,
                          body: nil,
                          completion: completion)
    }
    
    /// MARK: FETCH
    /// Perform Simple Asychronous request
    ///
    /// - parameter type: request type to call
    /// - parameter url: url string or uri string to append to baseURL if set
    /// - parameter headers: Optional headers to be set or append to baseHeaders if set
    /// - parameter body: Object to parse and send in request
    /// - returns: completion    /// - Returns error if exists, response if exists, data if exists
    public func FETCH(_ type: BenjiRequestType,
                      url: String,
                      headers: [String : String]?,
                      body: Any?,
                      completion: @escaping (_ error: Error?, _ response: HTTPURLResponse?, _ data:Any?) -> Void) {
        
        self.session.delegate = self.fetchDelegate
        self.session.fetchSession(self.getUrl(url: url),
                                  type: type,
                                  headers: self.combineHeaders(headers: headers),
                                  body: body,
                                  completion: completion)
    }
    
    /// MARK: DOWNLOADER
    public func DOWNLOAD(_ url:String,
                         headers: [String : String]?,
                         completion: @escaping (_ error: Error?, _ response: HTTPURLResponse?, _ data:Any?) -> Void) {

        return self.session.downloadSession(self.getUrl(url: url),
                                            type: .GET,
                                            headers: self.combineHeaders(headers: headers),
                                            delegate: self.downloadDelegate,
                                            completion: completion)
    }
    
    /// MARK: FILE UPLOADER
    public func UPLOAD(_ url:String,
                       type: BenjiRequestType,
                       headers: [String : String]?,
                       body:[String : Any]?,
                       fileName:String,
                       filePath: String,
                       completion: @escaping (_ error: Error?, _ response: HTTPURLResponse?, _ data:Any?) -> Void) {
                
        return self.session.uploadSession(url: self.getUrl(url: url),
                                   type: type,
                                   headers: self.combineHeaders(headers: headers),
                                   delegate: self.uploadDelegate,
                                   body: body,
                                   filePathKey: fileName,
                                   filePath: filePath,
                                   completion: completion)
    }
    
    // MARK: - STATIC DOWNLOADERS
    /// MARK: SYNCHRONOUS
    public static func syncFileDownload(_ url: String) -> Data? {
        if let urlObj = URL(string: url) {
            return try? Data(contentsOf: urlObj)
        }
        return nil
    }
    
    /// MARK: ASYNCHRONOUS
    public static func asyncFileDownload(_ url: String,
                                         completion: @escaping (_ error: Error?, _ data:Data?) -> Void) {
        let urlObj = URL(string: url)
        let session = URLSession.shared
        if let urlObj = urlObj {
            let task = session.dataTask(with: urlObj,
                                        completionHandler: { (data, response, error) -> Void in
                                            guard data != nil else {
                                                return completion(error, nil)
                                            }
                                            return completion(nil, data)
            })
            return task.resume()
        } else {
            return completion(nil, nil)
        }
    }
}

private extension Benji {
    
    // Append url to baseURL if set
    func getUrl(url: String) -> String {
        return self.baseURL != nil ? self.baseURL! + url : url
    }
    
    func combineHeaders(headers: [String : String]?) -> [String : String] {
        let mutableHeaders = headers != nil ? headers! : [:]
        return self.baseHeaders != nil ? self.baseHeaders!.merge(with: mutableHeaders) : mutableHeaders
    }
}

private extension Dictionary {
    /// Merge and return a new dictionary
    func merge(with: Dictionary<Key,Value>?) -> Dictionary<Key,Value> {
        var copy = self
        if let with = with {
            for (k, v) in with {
                // If a key is already present it will be overritten
                copy[k] = v
            }
        }
        return copy
    }
}

