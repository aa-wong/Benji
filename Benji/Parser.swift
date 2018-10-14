//
//  Parser.swift
//  Benji
//
//  Created by Aaron Wong-Ellis on 2018-09-16.
//  Copyright © 2018 aa-wong. All rights reserved.
//

import UIKit

struct Parser {
    
    static func dataFromJSON(data:[String : Any],
                             completion: (_ error: Error?, _ data: Data?) -> Void) {
        var jsonData : Data?
        do {
            jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
        } catch let error {
            return completion(error, nil)
        }
        return completion(nil, jsonData!)
    }
    
    static func JSONFromData(data: Data,
                             completion: (_ error: Error?, _ json: NSDictionary?) -> Void) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                return completion(nil, json)
            }
        } catch let error {
            return completion(error, nil)
        }
    }
}
