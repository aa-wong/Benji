//
//  Fetch.swift
//  Benji
//
//  Created by Aaron Wong-Ellis on 2018-09-16.
//  Copyright © 2018 kinactiv. All rights reserved.
//

import Foundation
import MobileCoreServices

@objc public protocol BenjiFetchDelegate {
    @objc optional func benjiDidGetProgressForFileUpload(_ uploadProgress:Float, percentageUploaded:Int)
    @objc optional func benjiDidGetErrorForFileUpload(_ error: Error)
    @objc optional func benjiLogRequest(_ log: [String : Any])
}

private enum BenjiRequestType {
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
    
    public static let fetch : Benji = Benji()
    
    private var uploadTask = URLSessionUploadTask()
    public var delegate : BenjiFetchDelegate?
    public var baseUrl : String?
    
    // MARK: - REQUESTERS
    // MARK: GET
    open func GET(_ uri:String, headers: [String : String]?, completion:@escaping (_ error: Error?, _ response:Any?) -> Void) {
        let type : BenjiRequestType = .GET
        let request : URLRequest = self.createRequestObject(method: type.requestString(),
                                                            uri: uri,
                                                            headers:headers)
        return self.urlSessionCaller(uri,
                                     postType: type.requestString(),
                                     request: request,
                                     completion: completion)
    }
    
    // MARK: POST
    open func POST(_ uri:String, headers: [String : String]?, parameters:[String : Any], completion:@escaping (_ error: Error?, _ response:Any?) -> Void) {
        let type : BenjiRequestType = .POST
        var request : URLRequest = self.createRequestObject(method: type.requestString(),
                                                            uri: uri,
                                                            headers:headers)
        
        Parser.dataFromJSON(data: parameters) { (error, data) in
            if (error != nil) {
                return completion(error, nil)
            }
            request.httpBody = data!
            return self.urlSessionCaller(uri,
                                         postType: type.requestString(),
                                         request: request,
                                         completion: completion)
        }
    }
    
    // MARK: PUT
    open func PUT(_ uri:String, headers: [String : String]?, parameters:[String : Any], completion:@escaping (_ error: Error?, _ response:Any?) -> Void) {
        let type : BenjiRequestType = .PUT
        var request : URLRequest = self.createRequestObject(method: type.requestString(),
                                                            uri: uri,
                                                            headers: headers)
        
        Parser.dataFromJSON(data: parameters) { (error, data) in
            if (error != nil) {
                return completion(error, nil)
            }
            request.httpBody = data!
            return self.urlSessionCaller(uri,
                                         postType: type.requestString(),
                                         request: request,
                                         completion: completion)
        }
    }
    
    // MARK: DELETE
    open func DELETE(_ uri:String, headers: [String : String]?, completion:@escaping (_ error: Error?, _ response:Any?) -> Void) {
        let type : BenjiRequestType = .DELETE
        let request : URLRequest = self.createRequestObject(method: type.requestString(),
                                                            uri: uri,
                                                            headers: headers)
        return self.urlSessionCaller(uri,
                                     postType: type.requestString(),
                                     request: request,
                                     completion: completion)
    }
    
    private func createRequestObject(method: String, uri: String, headers: [String : String]?) -> URLRequest {
        let url = self.baseUrl != nil ? self.baseUrl! + uri : uri
        let encodedUrl = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let uriRequest = URL(string: encodedUrl!)
        var request : URLRequest = URLRequest(url: uriRequest!)
        request.httpMethod = method
        
        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value,
                                 forHTTPHeaderField: key)
            }
        }
        
        self.passLogToDelegate(method: method, url: url, headers: headers)
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
    
    // MARK: FILE UPLOADER POST
    open func UPLOAD(_ uri:String, headers: [String : String]?, parameters:[String : Any]?, fileName:String, filePath: String, completion:@escaping (_ error: Error?, _ response: Any?) -> Void) {
        
        let url = self.baseUrl != nil ? self.baseUrl! + uri : uri
        
        let request = self.createDataUploadRequestWithParams(url,
                                                             headers:headers,
                                                             params: parameters)
        let data = self.createMultipartBodyWithParameters(parameters,
                                                          filePathKey: fileName,
                                                          paths: [filePath])
        self.uploadSessionCaller(url,
                                 request: request,
                                 data: data) { (response, success) -> Void in
            return completion(response, success)
        }
    }
    
    // MARK: - IMAGE DOWNLOADERS
    open static func asyncDownloadImageWithURL(_ urlString:String, completion:@escaping (_ error: Error?, _ image:UIImage?) -> Void) {
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
    
    open static func syncDownloadImageWithURL(_ urlString:String) -> UIImage {
        let url = URL(string: urlString)
        let imageData = try? Data(contentsOf: url!)
        let image = UIImage(data: imageData!)
        return image!
    }
    
    // MARK: - SESSION CALLERS
    // MARK: URL Session Caller
    open func urlSessionCaller(_ url:String, postType:String, request: URLRequest, completion:@escaping (_ error: Error?, _ response:Any?) -> Void) {
        
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
    open func uploadSessionCaller(_ url: String, request: URLRequest, data:Data, completion:@escaping (_ error:Error?, _ response:Any?) -> Void) {
        
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
    
    // MARK: MULTIPART/FORM-DATA Delegates
    // CREATE UPLOAD REQUEST
    open func createDataUploadRequestWithParams(_ url:String, headers: [String : String]?, params:[String:Any]?) -> URLRequest {
        
        let boundary = generateBoundaryString()
        let encodedUrl = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let uriRequest = URL(string: encodedUrl)
        let method : String = "POST"
        
        var request = URLRequest(url: uriRequest!)
        request.httpMethod = method
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.addValue("Keep-Alive", forHTTPHeaderField: "Connection")
        
        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        self.passLogToDelegate(method: method, url: url, headers: headers)
        
        return request
    }
    
    // Create body of the multipart/form-data request
    //
    // :param: parameters   The optional dictionary containing keys and values to be passed to web service
    // :param: filePathKey  The optional field name to be used when uploading files. If you supply paths, you must supply filePathKey, too.
    // :param: paths        The optional array of file paths of the files to be uploaded
    // :param: boundary     The multipart/form-data boundary
    //
    // :returns:            The NSData of the body of the request
    open func createMultipartBodyWithParameters(_ parameters: [String: Any]?, filePathKey: String?, paths: [String]?) -> Data {
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
                let data = try! Data(contentsOf: url)
                let mimetype = mimeTypeForPath(path)
                
                body.appendString("--\(boundary)\r\n")
                body.appendString("Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n")
                body.appendString("Content-Type: \(mimetype)\r\n\r\n")
                body.append(data)
                body.appendString("\r\n")
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
        return "application/octet-stream";
    }
    
    // MARK: Upload Session Delegates
    open func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let uploadProgress : Float = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        
        let uploadPercentage : Int =  Int(uploadProgress * 100)
        
        if let delegate = self.delegate,
            let didGetProgressForFileUpload = delegate.benjiDidGetProgressForFileUpload {
            return didGetProgressForFileUpload(uploadProgress, uploadPercentage)
        }
    }
    
    open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error,
            let delegate = self.delegate,
            let didGetErrorForFileUpload = delegate.benjiDidGetErrorForFileUpload {
            return didGetErrorForFileUpload(error)
        }
    }
    
    private func passLogToDelegate(method: String, url: String, headers: [String : String]?) {
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
