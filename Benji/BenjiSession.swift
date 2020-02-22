//
//  BenjiSession.swift
//  Benji
//
//  Created by Aaron Wong on 2019-11-21.
//  Copyright © 2019 Aaron Wong. All rights reserved.
//

import UIKit

@objc public protocol BenjiFetchDelegate {
    @objc optional func benjiDidGetError(_ error: Error)
    @objc optional func benjiLogRequest(_ log: [String : Any])
}

class BenjiSession: NSObject, URLSessionDelegate {
    
    var delegate: BenjiFetchDelegate?
    
    private var uploader : BenjiUploadManager?
    private var downloader : BenjiDownloadManager?
    private let requestFactory = BenjiRequestFactory()

    func createURLSession() -> URLSession {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config,
                          delegate: self,
                          delegateQueue: nil)
    }
    
    // MARK: Session Caller
    func fetchSession(_ url:String,
                     type: BenjiRequestType,
                     headers: [String : String],
                     body: Any?,
                     completion: @escaping (_ error: Error?, _ httpResponse: HTTPURLResponse?, _ data: Any?) -> Void) {
        
        // Apply header for JSON request
        var mutableHeaders = headers
        if headers["Content-Type"] == nil { mutableHeaders["Content-Type"] = "application/json" }
        
        // Create request object with url, type and headers
        if var request = self.requestFactory.createRequestObject(url: url,
                                                                 type: type,
                                                                 headers: headers) {
            self.passLogToDelegate(method: type.string(), url: url, headers: mutableHeaders)
            
            // If body exists, parse into JSON
            if let body = body {
                // Parsing to x-www-form-urlencoded
                if mutableHeaders["Content-Type"] == "application/x-www-form-urlencoded" {
                    if let body = body as? [AnyHashable : String] {
                        var postData = ""
                        body.forEach { (key, val) in
                            if (postData != "") { postData += "&" }
                            postData += "\(key)=\(val)"
                        }
                        request.httpBody = postData.data(using: String.Encoding.utf8)
                        return self.httpSession(url: url,
                                                request: request,
                                                completion: completion)
                    } else {
                        // Create error response when URLRequest object cannot be created
                        let error : Error = NSError(domain: "Invalid body data",
                                                    code: 412,
                                                    userInfo: ["more_info" : "application/x-www-form-urlencoded requires key-values as string"])
                        self.delegate?.benjiDidGetError?(error)
                        return completion(error, nil, nil)
                    }
                // Parsing JSON
                } else {
                    BenjiParser.dataFromObject(object: body) { (error, responseData) in
                        // Return if error exists
                        if let error = error {
                            self.delegate?.benjiDidGetError?(error)
                            return completion(error, nil, nil)
                        }
                        return self.httpSession(url: url,
                                                request: request,
                                                completion: completion)
                    }

                }
            } else {
                // Execute Session without body
                return self.httpSession(url: url,
                                        request: request,
                                        completion: completion)
            }
        } else {
            // Create error response when URLRequest object cannot be created
            let error : Error = NSError(domain: "Request", code: 412, userInfo: ["more_info" : "url \(url) could not be encoded."])
            self.delegate?.benjiDidGetError?(error)
            return completion(error, nil, nil)
        }
    }
    
    func httpSession(url: String, request: URLRequest, completion: @escaping (_ error: Error?, _ httpResponse: HTTPURLResponse?, _ data: Any?) -> Void) {
        let session = self.createURLSession()
        let task = session.dataTask(with: request) { (data, response, error) in
            return self.parseReturnedResponse(request: request,
                                              data: data,
                                              response: response,
                                              error: error,
                                              completion: completion)
        }
        return task.resume()
    }
    
    // MARK: UPLOAD Session Caller
    func uploadSession(url: String,
                       type: BenjiRequestType,
                       headers: [String : String],
                       delegate: BenjiUploadDelegate?,
                       body: [String : Any]?,
                       filePathKey: String,
                       filePath: String,
                       completion: @escaping (_ error:Error?, _ response:HTTPURLResponse?, _ data: Any?) -> Void) {
        
        if self.uploader == nil {
            self.uploader = BenjiUploadManager()
        }
        
        self.uploader!.delegate = delegate
        
        if type != .POST || type != .PUT {
            // Create error response when URLRequest object cannot be created
            let error : Error = NSError(domain: "Request",
                                        code: 412,
                                        userInfo: [
                                            "more_info" : "Uploading can only be executed with a POST or PUT request"])
            self.delegate?.benjiDidGetError?(error)
            return completion(error, nil, nil)
        }
        
        let boundary = self.uploader!.generateBoundaryString()
        var mutableHeaders = headers
        mutableHeaders["Content-Type"] = "multipart/form-data; boundary=\(boundary)"
        mutableHeaders["Connection"] = "Keep-Alive"
        
        self.passLogToDelegate(method: type.string(), url: url, headers: mutableHeaders)
        
        // Create request object with url, type and headers
        if let request = self.requestFactory.createRequestObject(url: url,
                                                                 type: type,
                                                                 headers: mutableHeaders) {
            
            if let data = self.uploader!.createMultipartBodyWithParameters(body,
                                                                           boundary: boundary,
                                                                           filePathKey: filePathKey,
                                                                           paths: [filePath]) {
                let session = self.createURLSession()
                self.uploader!.caller(session, request: request, data: data) { (error, response, data) in
                    return self.parseReturnedResponse(request: request,
                                                      data: data,
                                                      response: response,
                                                      error: error,
                                                      completion: completion)
                }
            } else {
                let error : Error = NSError(domain: "Preparation", code: 409, userInfo: ["more_info" : "Could not prepare upload data"])
                let response = HTTPURLResponse(url: request.url!, statusCode: 409, httpVersion: nil, headerFields: request.allHTTPHeaderFields)
                return completion(error, response, nil)
            }
        } else {
            // Create error response when URLRequest object cannot be created
            let error : Error = NSError(domain: "Request", code: 412, userInfo: ["more_info" : "url \(url) could not be encoded."])
            self.delegate?.benjiDidGetError?(error)
            return completion(error, nil, nil)
            
        }
    }
    
    // MARK: DOWNLOAD Session Caller
    func downloadSession(_ url: String,
                         type: BenjiRequestType,
                         headers: [String : String],
                         delegate: BenjiDownloadDelegate?,
                         completion: @escaping (_ error:Error?, _ response:HTTPURLResponse?, _ data: Data?) -> Void) {
        
        if self.downloader == nil {
            self.downloader = BenjiDownloadManager()
        }
        
        self.downloader!.delegate = delegate
        
        self.passLogToDelegate(method: type.string(), url: url, headers: headers)
        
        if let request = self.requestFactory.createRequestObject(url: url, type: type, headers: headers) {
            return self.downloader!.caller(url, request: request, completion: completion)
        } else {
            // Create error response when URLRequest object cannot be created
            let error : Error = NSError(domain: "Request", code: 412, userInfo: ["more_info" : "url \(url) could not be encoded."])
            self.delegate?.benjiDidGetError?(error)
            return completion(error, nil, nil)
            
        }
    }
    
    func parseReturnedResponse(request: URLRequest,
                                      data: Data?,
                                      response: URLResponse?,
                                      error: Error?,
                                      completion: @escaping (
        _ error:Error?,
        _ response:HTTPURLResponse?,
        _ data: Any?) -> Void) {
        
        if let http = response as? HTTPURLResponse {
            guard error == nil else {
                return completion(error, http, nil)
            }
            BenjiParser.objectFromData(data: data!,
                                     completion: { (error, json) in
                                        if (error != nil) {
                                            return completion(error, http, nil)
                                            
                                        }
                                        return completion(nil, http, json)
            })
        } else {
            let error : Error = NSError(domain: "Server",
                                        code: 504,
                                        userInfo: ["more_info" : "No Server response"])
            let response = HTTPURLResponse(url: request.url!,
                                           statusCode: 504,
                                           httpVersion: nil,
                                           headerFields: request.allHTTPHeaderFields)
            return completion(error, response, nil)
        }
    }
}

// MARK: - BENJI DELEGATES
extension BenjiSession {
    private func passLogToDelegate(method: String,
                                   url: String,
                                   headers: [String : String]?) {
        
        if let delegate = self.delegate,
            let logger = delegate.benjiLogRequest {
            var details : [String : Any] = [:]
            details["request_type"] = method
            details["url"] = url
            if let headers = headers { details["headers"] = headers }
            return logger(details)
        }
    }
}
