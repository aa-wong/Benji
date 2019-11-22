//
//  BenjiParser.swift
//  Benji
//
//  Created by Aaron Wong on 2019-11-21.
//  Copyright © 2019 Aaron Wong. All rights reserved.
//

import UIKit

public class BenjiParser: NSObject {
    public static func dataFromObject(object: Any,
                                      completion: (_ error: Error?, _ data: Data?) -> Void) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: object, options: [])
            return completion(nil, jsonData)
        } catch let error {
            return completion(error, nil)
        }
        
    }
    
    public static func objectFromData(data: Data,
                                      completion: (_ error: Error?, _ json: Any?) -> Void) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return completion(nil, json)
        } catch let error {
            return completion(error, nil)
        }
    }
}
