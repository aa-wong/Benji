//
//  BenjiDownloadManager.swift
//  Benji
//
//  Created by Aaron Wong on 2019-11-21.
//  Copyright © 2019 Aaron Wong. All rights reserved.
//

import UIKit

@objc public protocol BenjiDownloadDelegate: BenjiFetchDelegate {
    @objc optional func benjiDidGetDownloadProgress(_ progress:Float, percentage:Int)
    @objc optional func benjiDownloadComplete(_ location: URL)
}

class BenjiDownloadManager : NSObject, URLSessionDownloadDelegate {
    
    var delegate : BenjiDownloadDelegate?
    
    var session : URLSession {
        get {
            return URLSession(configuration: .default)
        }
    }
    
    // MARK: DOWNLOAD Session Caller
    func caller(_ url: String,
                request: URLRequest,
                completion: @escaping (_ error:Error?, _ response:HTTPURLResponse?, _ data: Data?) -> Void) {
        
        let task = self.session.downloadTask(with: request,
                                             completionHandler: { (localUrl, response, error) in
            return self.parseDownloadResponse(request: request,
                                              url: localUrl,
                                              response: response,
                                              error: error,
                                              completion: completion)
        })
        return task.resume()
    }
    
    func parseDownloadResponse(request: URLRequest,
                               url: URL?,
                               response: URLResponse?,
                               error: Error?,
                               completion: @escaping (_ error:Error?, _ response:HTTPURLResponse?, _ data: Data?) -> Void) {
        
        if let http = response as? HTTPURLResponse {
            guard error == nil else {
                return completion(error, nil, nil)
            }
            
            do {
                let data = try Data(contentsOf: url!)
                return completion(nil, http, data)
            } catch {
                return completion(error, http, nil)
            }
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
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        
        if totalBytesExpectedToWrite > 0 {
            let progress : Float = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            let percentage : Int = Int(progress * 100)
            self.delegate?.benjiDidGetDownloadProgress?(progress,
                                                        percentage: percentage)
        }
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        self.delegate?.benjiDownloadComplete?(location)
    }
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        if let error = error {
            self.delegate?.benjiDidGetError?(error)
        }
    }
    
    func calculateProgress(session: URLSession,
                           completion: @escaping (Float) -> ()) {
        session.getTasksWithCompletionHandler { (tasks, uploads, downloads) in
            let bytesReceived = downloads.map{ $0.countOfBytesReceived }.reduce(0, +)
            let bytesExpectedToReceive = downloads.map{ $0.countOfBytesExpectedToReceive }.reduce(0, +)
            let progress = bytesExpectedToReceive > 0 ? Float(bytesReceived) / Float(bytesExpectedToReceive) : 0.0
            return completion(progress)
        }
    }
}
