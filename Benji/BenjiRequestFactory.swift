//
//  BenjiRequestFactory.swift
//  Benji
//
//  Created by Aaron Wong on 2019-11-21.
//  Copyright © 2019 Aaron Wong. All rights reserved.
//

import Foundation

class BenjiRequestFactory: NSObject {
    
    // MARK: - HTTP REQUEST HELPERS
    // MARK: URL Request Object
    func createRequestObject(url: String,
                             type: BenjiRequestType,
                             headers: [String : String]?) -> URLRequest? {
        
        if let encodedUrl = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let urlObj = URL(string: encodedUrl) {
            var request : URLRequest = URLRequest(url: urlObj)
            request.httpMethod = type.string()
            return self.processHeaders(request: request,
                                       headers: headers)
        }
        return nil
    }
    
    // MARK: Serialize headers
    func processHeaders(request: URLRequest,
                        headers: [String : String]?) -> URLRequest {
        var urlRequest = request
        if let headers = headers {
            headers.forEach { (key, value) in urlRequest.addValue(value, forHTTPHeaderField: key) }
        }
        return urlRequest
    }
}

