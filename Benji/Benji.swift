//
//  Fetch.swift
//  Benji
//
//  Created by Aaron Wong-Ellis on 2018-09-16.
//  Copyright © 2018 aa-wong. All rights reserved.
//

import Foundation
import MobileCoreServices

@objc public protocol BenjiFetchDelegate {
    @objc optional func benjiDidGetProgressForFileUpload(_ uploadProgress:Float, percentageUploaded:Int)
    @objc optional func benjiDidGetErrorForFileUpload(_ error: Error)
    @objc optional func benjiLogRequest(_ log: [String : Any])
}

public enum BenjiRequestType {
    case GET
    case POST
    case PUT
    case DELETE
    
    func requestString() -> String {
        switch self {
        case .GET:
            return "GET"
        case .POST:
            return "POST"
        case .PUT:
            return "PUT"
        case .DELETE:
            return "DELETE"
        }
    }
}

public class Benji: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
    
    private struct Static {
        static var instance: Benji?
    }
    
    public class var shared: Benji {
        if Static.instance == nil {
            Static.instance = Benji()
        }
        return Static.instance!
    }
    
    public static func destroy() {
        Benji.Static.instance = nil
    }
    
    private var uploadTask = URLSessionUploadTask()
    public var delegate : BenjiFetchDelegate?
    public var baseUrl : String?
    public var baseHeaders : [String : String]?
    
    // MARK: - REQUESTERS
    // MARK: GET
    open func GET(_ url:String,
                  headers: [String : String]?,
                  completion:@escaping (_ error: Error?, _ response:Any?) -> Void) {
        
        return self.FETCH(.GET,
                          url: url,
                          headers: headers,
                          parameters: nil,
                          completion: completion)
    }
    
    // MARK: POST
    open func POST(_ url:String,
                   headers: [String : String]?,
                   parameters:[String : Any],
                   completion: @escaping (_ error: Error?, _ response:Any?) -> Void) {
        
        return self.FETCH(.POST,
                          url: url,
                          headers: headers,
                          parameters: parameters,
                          completion: completion)
    }
    
    // MARK: PUT
    open func PUT(_ url:String,
                  headers: [String : String]?,
                  parameters:[String : Any],
                  completion: @escaping (_ error: Error?, _ response:Any?) -> Void) {
        
        return self.FETCH(.PUT,
                          url: url,
                          headers: headers,
                          parameters: parameters,
                          completion: completion)
    }
    
    // MARK: DELETE
    open func DELETE(_ url:String,
                     headers: [String : String]?,
                     completion: @escaping (_ error: Error?, _ response:Any?) -> Void) {
        
        return self.FETCH(.DELETE,
                          url: url,
                          headers: headers,
                          parameters: nil,
                          completion: completion)
    }
    
    // MARK: REQUESTER
    open func FETCH(_ type: BenjiRequestType,
                    url: String,
                    headers: [String : String]?,
                    parameters:[String : Any]?,
                    completion: @escaping (_ error: Error?, _ response:Any?) -> Void) {
        
        let requestUrl = self.baseUrl != nil ? self.baseUrl! + url : url
        
        var request : URLRequest = self.createRequestObject(method: type.requestString(),
                                                            url: requestUrl,
                                                            headers: headers)
        if let parameters = parameters {
            Parser.dataFromJSON(data: parameters) { (error, data) in
                if (error != nil) {
                    return completion(error, nil)
                }
                request.httpBody = data!
                return self.urlSessionCaller(url,
                                             request: request,
                                             completion: completion)
            }
        } else {
            return self.urlSessionCaller(url,
                                         request: request,
                                         completion: completion)
        }
    }
    
    // MARK: FILE UPLOADER POST
    open func UPLOAD(_ uri:String,
                     type: BenjiRequestType,
                     headers: [String : String]?,
                     parameters:[String : Any]?,
                     fileName:String,
                     filePath: String,
                     completion: @escaping (_ error: Error?, _ response: Any?) -> Void) {
        
        let url = self.baseUrl != nil ? self.baseUrl! + uri : uri
        
        let request = self.createDataUploadRequestWithParams(url,
                                                             type: type,
                                                             headers: headers)
        
        if let data = self.createMultipartBodyWithParameters(parameters,
                                                          filePathKey: fileName,
                                                          paths: [filePath]) {
            self.uploadSessionCaller(url,
                                     request: request,
                                     data: data) { (response, success) -> Void in
                                        return completion(response, success)
            }
        } else {
            let error : Error = NSError(domain: "Error occured while preparing file for upload", code: 409, userInfo: nil)
            return completion(error, nil)
        }
    }
    
    // MARK: - IMAGE DOWNLOADERS
    
    // MARK: SYNCHRONOUS
    public static func syncImageDownloadWithURL(_ urlString:String) -> UIImage {
        let url = URL(string: urlString)
        let imageData = try? Data(contentsOf: url!)
        let image = UIImage(data: imageData!)
        return image!
    }

    // MARK: ASYNCHRONOUS
    public static func asyncImageDownloadWithURL(_ urlString:String,
                                                 completion: @escaping (_ error: Error?, _ image:UIImage?) -> Void) {
        let url = URL(string: urlString)
        let session = Foundation.URLSession.shared
        let task = session.dataTask(with: url!,
                                    completionHandler: { (data, response, error) -> Void in
                                        guard data != nil else {
                                            return completion(error, nil)
                                        }
                                        
                                        do {
                                            let image = UIImage(data: data!)
                                            return completion(nil, image)
                                        }
        })
        return task.resume()
    }
    
    // MARK: - SESSION CALLERS
    
    // MARK: URL Request Object
    private func createRequestObject(method: String,
                                     url: String,
                                     headers: [String : String]?) -> URLRequest {
        
        let encodedUrl = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let uriRequest = URL(string: encodedUrl!)
        var request : URLRequest = URLRequest(url: uriRequest!)
        request.httpMethod = method
        return self.processHeaders(request: request, headers: headers)
    }
    
    // MARK: Headers
    private func processHeaders(request: URLRequest, headers: [String : String]?) -> URLRequest {
        var pre : [String : String]?
        
        if var baseHeaders = self.baseHeaders {
            if let headers = headers {
                headers.forEach { (key, value) in baseHeaders[key] = value }
            } else {
                pre = baseHeaders
            }
        } else {
            pre = headers
        }
        
        var urlRequest = request
        
        if let post = pre {
            for (key, value) in post {
                urlRequest.addValue(value, forHTTPHeaderField: key)
            }
        }
        self.passLogToDelegate(method: request.httpMethod!, url: request.url!.absoluteString, headers: headers)
        
        return urlRequest
    }
    
    // MARK: URL Session Caller
    private func urlSessionCaller(_ url:String,
                               request: URLRequest,
                               completion: @escaping (_ error: Error?, _ response:Any?) -> Void) {
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                return completion(error, nil)
            }
            
            Parser.JSONFromData(data: data!,
                                completion: { (error, json) in
                if (error != nil) {
                    return completion(error, nil)
                }
                return completion(nil, json)
            })
        }
        
        return task.resume()
    }
    
    // MARK: Upload Session Caller
    private func uploadSessionCaller(_ url: String,
                                  request: URLRequest,
                                  data:Data,
                                  completion: @escaping (_ error:Error?, _ response:Any?) -> Void) {
        
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 1
        
        let uploadSession = Foundation.URLSession(configuration: config,
                                                  delegate: self,
                                                  delegateQueue: nil)
        
        self.uploadTask = uploadSession.uploadTask(with: request,
                                                   from: data,
                                                   completionHandler: { (data, response, error) -> Void in
            
            guard error == nil else {
                return completion(error, nil)
            }
            
            Parser.JSONFromData(data: data!,
                                         completion: { (error, json) in
                if (error != nil) {
                    return completion(error, nil)
                }
                return completion(nil, json)
            })
        })
        return uploadTask.resume()
    }
    
    // MARK: MULTIPART/FORM-DATA
    // CREATE UPLOAD REQUEST
    private func createDataUploadRequestWithParams(_ url:String,
                                                type: BenjiRequestType,
                                                headers: [String : String]?) -> URLRequest {
        
        let boundary = generateBoundaryString()
        let encodedUrl = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let uriRequest = URL(string: encodedUrl)
        let method : String = type.requestString()
        
        var request = URLRequest(url: uriRequest!)
        request.httpMethod = method
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.addValue("Keep-Alive", forHTTPHeaderField: "Connection")
        return self.processHeaders(request: request, headers: headers)
    }
    
    // Create body of the multipart/form-data request
    //
    // :param: parameters   The optional dictionary containing keys and values to be passed to web service
    // :param: filePathKey  The optional field name to be used when uploading files. If you supply paths, you must supply filePathKey, too.
    // :param: paths        The optional array of file paths of the files to be uploaded
    // :param: boundary     The multipart/form-data boundary
    //
    // :returns:            The NSData of the body of the request
    private func createMultipartBodyWithParameters(_ parameters: [String: Any]?,
                                                filePathKey: String?,
                                                paths: [String]?) -> Data? {
        let body = NSMutableData()
        
        let boundary = generateBoundaryString()
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.appendString("--\(boundary)\r\n")
                body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString("\(value)\r\n")
            }
        }
        
        if paths != nil {
            for path in paths! {
                let url = URL(fileURLWithPath: path)
                let filename = url.lastPathComponent
                
                do {
                    let data = try Data(contentsOf: url)
                    let mimetype = mimeTypeForPath(path)
                    
                    body.appendString("--\(boundary)\r\n")
                    body.appendString("Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n")
                    body.appendString("Content-Type: \(mimetype)\r\n\r\n")
                    body.append(data)
                    body.appendString("\r\n")
                } catch let error {
                    self.delegate?.benjiDidGetErrorForFileUpload?(error)
                    return nil
                }
            }
        }
        
        body.appendString("--\(boundary)--\r\n")
        return body as Data
    }
    
    // Create boundary string for multipart/form-data request
    // :returns:            The boundary string that consists of "Boundary-" followed by a UUID string
    private func generateBoundaryString() -> String {
        return "Boundary-\(UUID().uuidString)"
    }
    
    // Determine mime type on the basis of extension of a file.
    // This requires MobileCoreServices framework.
    // :param: path         The path of the file for which we are going to determine the mime type.
    // :returns:            Returns the mime type if successful. Returns application/octet-stream if unable to determine mime type.
    private func mimeTypeForPath(_ path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let pathExtension = url.pathExtension
        
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                           pathExtension as NSString, nil)?.takeRetainedValue(),
            let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
            return mimetype as String
        }
        return "application/octet-stream"
    }
    
    // MARK: Upload Session Delegates
    private func urlSession(_ session: URLSession,
                         task: URLSessionTask,
                         didSendBodyData bytesSent: Int64,
                         totalBytesSent: Int64,
                         totalBytesExpectedToSend: Int64) {
        
        let uploadProgress : Float = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        let uploadPercentage : Int =  Int(uploadProgress * 100)
        self.delegate?.benjiDidGetProgressForFileUpload?(uploadProgress, percentageUploaded: uploadPercentage)
    }
    
    private func urlSession(_ session: URLSession,
                         task: URLSessionTask,
                         didCompleteWithError error: Error?) {
        
        if let error = error {
            self.delegate?.benjiDidGetErrorForFileUpload?(error)
        }
    }
    
    private func passLogToDelegate(method: String,
                                   url: String,
                                   headers: [String : String]?) {
        
        if let delegate = self.delegate,
            let logger = delegate.benjiLogRequest {
            var details : [String : Any] = [:]
            details["post_type"] = method
            details["url"] = url
            if let headers = headers { details["headers"] = headers }
            return logger(details)
        }
    }
}

extension NSMutableData {
    
    /// Append string to NSMutableData
    ///
    /// Rather than littering my code with calls to `dataUsingEncoding` to convert strings to NSData, and then add that data to the NSMutableData, this wraps it in a nice convenient little extension to NSMutableData. This converts using UTF-8.
    ///
    /// :param: string       The string to be added to the `NSMutableData`.
    
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}
