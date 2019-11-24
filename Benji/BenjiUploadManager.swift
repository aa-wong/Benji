//
//  BenjiUploadManager.swift
//  Benji
//
//  Created by Aaron Wong on 2019-11-21.
//  Copyright © 2019 Aaron Wong. All rights reserved.
//

import Foundation
import MobileCoreServices

@objc public protocol BenjiUploadDelegate: BenjiFetchDelegate {
    @objc optional func benjiDidGetUploadProgress(_ progress:Float, percentage:Int)
    @objc optional func benjiUploadComplete(_ location: URL)
}

class BenjiUploadManager: NSObject {
    
    var delegate : BenjiUploadDelegate?
    
    // MARK: Session Caller
    func caller(_ session: URLSession,
                request: URLRequest,
                data: Data,
                completion: @escaping (_ error:Error?, _ response:URLResponse?, _ data: Data?) -> Void) {
        let task = session.uploadTask(with: request,
                                      from: data,
                                      completionHandler: { (data, response, error) -> Void in
            return completion(error, response, data)
        })
        return task.resume()
    }

    //MARK: Create body of the multipart/form-data request
    func createMultipartBodyWithParameters(_ parameters: [String: Any]?,
                                           boundary: String,
                                           filePathKey: String,
                                           paths: [String]) -> Data? {
        var body = Data()
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append("\(value)\r\n")
            }
        }
        
        for path in paths {
            let url = URL(fileURLWithPath: path)
            let filename = url.lastPathComponent
            
            do {
                let data = try Data(contentsOf: url)
                let mimetype = self.mimeTypeForPath(path)
                
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(filePathKey)\"; filename=\"\(filename)\"\r\n")
                body.append("Content-Type: \(mimetype)\r\n\r\n")
                body.append(data)
                body.append("\r\n")
            } catch let error {
                self.delegate?.benjiDidGetError?(error)
                return nil
            }
        }
        body.append("--\(boundary)--\r\n")
        return body as Data
    }
    
    //MARK: Create boundary string for multipart/form-data request
    func generateBoundaryString() -> String {
        return "Boundary-\(UUID().uuidString)"
    }
    
    //MARK: Determine mime type on the basis of extension of a file.
    func mimeTypeForPath(_ path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let pathExtension = url.pathExtension
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                           pathExtension as NSString,
                                                           nil)?.takeRetainedValue(),
            let mimetype = UTTypeCopyPreferredTagWithClass(uti,
                                                           kUTTagClassMIMEType)?.takeRetainedValue() {
            return mimetype as String
        }
        return "application/octet-stream"
    }
}

extension BenjiUploadManager: URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
    //MARK: Extension of URL Session to return upload progress to BenjiUploadDelegate
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        if totalBytesExpectedToSend > 0 {
            let progress : Float = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
            let percentage : Int = Int(progress * 100)
            self.delegate?.benjiDidGetUploadProgress?(progress, percentage: percentage)
            
            if percentage === 100 {
                self.delegate?.benjiUploadComplete?(<#T##location: URL##URL#>)
            }
        }
    }
}

extension Data {
    
    /// Append string to Data
    mutating func append(_ string: String, using encoding: String.Encoding = .utf8) {
        if let data = string.data(using: encoding) {
            append(data)
        }
    }
}
