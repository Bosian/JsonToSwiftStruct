//
//  ViewController.swift
//  JsonConverterTest
//
//  Created by 劉柏賢 on 2016/11/1.
//  Copyright © 2016年 劉柏賢. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func printJsonModel(_ sender: UIButton) {
        printJsonModel()
    }
    
    @IBAction func printJsonString(_ sender: UIButton) {
        printJsonString()
    }
    
    @IBAction func printJsonArray(_ sender: UIButton) {
        printJsonArray()
    }
    
    @IBAction func printNativeJsonArray(_ sender: UIButton) {
        printNativeJsonArray()
    }
}

extension ViewController {

    fileprivate func printJsonString() {
        
        let skills = (1...10).map { Model.Skill(name: String($0)) }
        let model = Model(skill: skills, other: Model.Other(info: "other info"))
        let json = model.toJsonString(.prettyPrinted)
        
        print("\r\n\r\n")
        print("Json: \(json)")
        print("\r\n\r\n")
        print("Model: \(model)")
    }
    
    fileprivate func printJsonArray() {
        
        let skills = (1...10).map { Model.Skill(name: String($0)) }
        let model = Model(skill: skills, other: Model.Other(info: "other info"))
        let json = model.skill.toJsonString(.prettyPrinted)
        
        print("\r\n\r\n")
        print("Json: \(json)")
        print("\r\n\r\n")
        print("Model: \(model)")
    }
    
    fileprivate func printNativeJsonArray() {
        let skills = (1...10).map { Model.Skill(name: String($0)) }
        let native = (1...10).map { String($0) }
        let model = Model(skill: skills, native: native)
        let json = model.native?.toJsonString(.prettyPrinted) ?? "[]"
        
        print("\r\n\r\n")
        print("Json: \(json)")
        print("\r\n\r\n")
        print("Model: \(model)")
    }
    
    fileprivate func printJsonModel()
    {
        let jsonString = "{\"metadata\":{\"status\":\"0000\",\"desc\":\"正確\"},\"data\":{\"wishlists\":[{\"id\":1854,\"is_success\":false},{\"id\":11831,\"is_success\":true}]}}"
        guard let data = jsonString.data(using: .utf8) else {
            return
        }
        
        var dictionary: JsonDictionary?
        
        do {
            dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? JsonDictionary
        }
        catch let error
        {
            print(error.localizedDescription)
            return
        }
        
        guard let dictionaryUnwrapped = dictionary else {
            return
        }
        
        let key = "Root"
        convertToModel(for: dictionaryUnwrapped, withKey: key)
    }
    
    /// 將 Dictionary 輸出成 Json String
    ///
    /// - Parameters:
    ///   - dictionary: Json Dictionary
    ///   - key: Root struct Name
    private func convertToModel(for dictionary: JsonDictionary, withKey key: String)
    {
        var pendingJsonDictionary: [(key: String, value: JsonDictionary)] = []
        var pendingInit: [(key: String, type: String)] = []
        var pendingJsonMapping: [String] = []
        
        // 輸出 struct 開頭
        let typeName = uppercaseedFirstChar(for: key)
        print("public struct \(typeName): \(JsonDeserializeable.self) {\r\n")
        
        let tabSapce = "    "
        
        for (key, value) in dictionary {

            let key = camelCase(for: key)
            
            switch value {
            case _ as String:
                print("\(tabSapce)public var \(key): String = \"\"")

                pendingInit.append((key: key, type: "String"))
                
                pendingJsonMapping.append("self.\(key) = jsonDictionary[\"\(key)\"].stringOrDefault")
                
            case _ as Int:
                
                let defaultValue = -1
                print("\(tabSapce)public var \(key): Int = \(defaultValue)")
                
                pendingInit.append((key: key, type: "Int"))
                
                pendingJsonMapping.append("self.\(key) = jsonDictionary[\"\(key)\"].intOrDefault")
                
            case _ as Bool:
                print("\(tabSapce)public var \(key): Bool = false")
                
                pendingInit.append((key: key, type: "Bool"))
                
                pendingJsonMapping.append("self.\(key) = jsonDictionary[\"\(key)\"].boolOrDefault")
                
            case _ as Double:
                print("\(tabSapce)public var \(key): Double = 0.0")
                
                pendingInit.append((key: key, type: "Double"))
                
                pendingJsonMapping.append("self.\(key) = jsonDictionary[\"\(key)\"].doubleOrDefault")
                
            case _ as [String]:
                print("\(tabSapce)public var \(key): [String] = []")
                
                pendingInit.append((key: key, type: "[String]"))
                
                pendingJsonMapping.append("self.\(key) = jsonDictionary[\"\(key)\"].stringArrayOrDefault")
                
            case _ as [Int]:
                print("\(tabSapce)public var \(key): [Int] = []")
                
                pendingInit.append((key: key, type: "[Int]"))
                
                pendingJsonMapping.append("self.\(key) = jsonDictionary[\"\(key)\"].intArrayOrDefault")
                
            case _ as [Double]:
                print("\(tabSapce)public var \(key): [Double] = []")
                
                pendingInit.append((key: key, type: "[Double]"))
                
                pendingJsonMapping.append("self.\(key) = jsonDictionary[\"\(key)\"].doubleArrayOrDefault")
                
            case let value as JsonDictionary:
                
                let typeName = uppercaseedFirstChar(for: key)
                print("\(tabSapce)public var \(key): \(typeName) = \(typeName)()")
                
                pendingInit.append((key: key, type: "\(typeName)"))
                
                pendingJsonDictionary.append((key, value))
                pendingJsonMapping.append("self.\(key) = \(typeName)(jsonDictionary: jsonDictionary[\"\(key)\"].jsonDictionaryOrDefault)")
                
                
            case let value as JsonArray:
                
                let typeName = uppercaseedFirstChar(for: key)
                print("\(tabSapce)public var \(key): [\(typeName)] = []")
                
                pendingInit.append((key: key, type: "[\(typeName)]"))
                
                guard let value = value.first else {
                    continue
                }
                
                pendingJsonDictionary.append((key, value))
                pendingJsonMapping.append("self.\(key) = [\(typeName)](jsonArray: jsonDictionary[\"\(key)\"].jsonArrayOrDefault)")
                
            default:
                print("...無法剖析 \(tabSapce)public var \(key): String = \"\"")
                
                pendingInit.append((key: key, type: "String ...無法剖析"))
                
                pendingJsonMapping.append("...無法剖析 self.\(key) = jsonDictionary[\"\(key)\"].stringOrDefault")
            }
        }
        
        // 輸出 JsonDeserializeable 實作
        print()
        print("\(tabSapce)public init()")
        print("\(tabSapce){")
        print("\(tabSapce)")
        print("\(tabSapce)}")
        
        print("\(tabSapce)")
        
        print("\(tabSapce)public init(\(pendingInit.map { "\($0.key): \($0.type)" }.joined(separator: ", ")))")
        print("\(tabSapce){")
        
        for item in pendingInit {
            print("\(tabSapce)\(tabSapce)self.\(item.key) = \(item.key)")
        }
        print("\(tabSapce)}")
        
        print("\(tabSapce)")
        
        print("\(tabSapce)public mutating func jsonMapping(_ jsonDictionary: JsonDictionary)")
        print("\(tabSapce){")
        
        for item in pendingJsonMapping {
            print("\(tabSapce)\(tabSapce)\(item)")
        }
            
        print("\(tabSapce)}")
        
        // 輸出 struct 後大刮號
        print("}\r\n")
        
        for (key, dictionary) in pendingJsonDictionary {
            convertToModel(for: dictionary, withKey: key)
        }
    }
    
    /// 首字轉大寫
    ///
    /// - Parameter str: 字串
    /// - Returns: 回傳首字轉大寫後字串
    private func uppercaseedFirstChar(for str: String?) -> String
    {
        guard let str = str else {
            return ""
        }
        
        guard let firstChar = str.characters.first else {
            return ""
        }
        
        // struct name 首字大寫
        let firstCharUppercased = String(firstChar).uppercased()
        let othersKeyChar = str.substring(from: str.index(str.startIndex, offsetBy: 1))
        
        return "\(firstCharUppercased)\(othersKeyChar)"
    }
    
    /// 首字轉小寫
    ///
    /// - Parameter str: 字串
    /// - Returns: 回傳首字轉小寫後字串
    private func lowercaseedFirstChar(for str: String?) -> String
    {
        guard let str = str else {
            return ""
        }
        
        guard let firstChar = str.characters.first else {
            return ""
        }
        
        // struct name 首字小寫
        let firstCharLowercased = String(firstChar).lowercased()
        let othersKeyChar = str.substring(from: str.index(str.startIndex, offsetBy: 1))
        
        return "\(firstCharLowercased)\(othersKeyChar)"
    }
    
    /// 小駝峰式命名法（lower camel case）
    private func camelCase(for str: String) -> String {
        
        let stringArray = str.replacingOccurrences(of: " ", with: "_")
                       .replacingOccurrences(of: "-", with: "_")
                       .components(separatedBy: "_")
        
        // 首字轉小寫
        let firstWord = lowercaseedFirstChar(for: stringArray.first)
        
        // 單字小於3個字母則全轉大寫
        var otherStringArray = stringArray.dropFirst().map { $0.characters.count > 3 ? uppercaseedFirstChar(for: $0) : $0.uppercased() }
        otherStringArray.insert(firstWord, at: 0)
        
        return otherStringArray.joined()
    }
}
