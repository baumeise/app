//
//  Settings.swift
//  Amsel
//
//  Created by Anja on 01.01.20.
//  Copyright © 2020 Anja. All rights reserved.
//

import Foundation

class Settings: Codable {
    private var xx: String {
        didSet {
            save()
        }
    }
    
    init() {
        let defaults = UserDefaults.standard
        if let settingsData = defaults.object(forKey: "Settings") as? Data,
            let settings = try? PropertyListDecoder().decode(Settings.self, from: settingsData) {
            self.xx = settings.xx
        } else {
            xx = ""
        }
    }
    
    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(try? PropertyListEncoder().encode(self), forKey: "Settings")
    }
    
    public func setXX(_ xx: String) {
        self.xx = xx
    }
    
    public func getXX() -> String {
        return xx
    }
}

struct Lessons: Decodable {
    var lessons: [Lesson]
}
struct Lesson: Decodable {
    var id: String
    var index: Int
    var title: String
    var sections: [Section]
}
struct Section: Decodable {
    var id: String
    var index: Int
    var title: String
    var task: String
    var multipleChoice: [Choice]?
    var codeBlock: [CodeBlock]?
    var feedbackFailed: String?
    var feedbackPassed: String?
    var amselInteraction: Bool?
    var amselAction: AmselAction?
    
    func getSectionedCodeBlock() -> [[CodeBlock]]? {
        // In the collection view all new lines are represented by a section change. This function goes through the section's code blocks, creates code lines and searches for new lines to separated into sections.
        
        // If code blocks are available in current section
        if let codeBlocks = self.codeBlock {
            var codeSections = [[CodeBlock]]() // append here, if newline is wanted
            var codeLines = [CodeBlock]() // append here, if code is in same line
            
            for codeBlock in codeBlocks {
                switch codeBlock.type {
                case .code:
                    // Parse string of "Code" type for new lines and append sections (except of the last string)
                    let splittedStrings = codeBlock.content.safeNewLineSplit
                    for (index, splittedString) in splittedStrings.enumerated() {
                        let splittedCodeBlock = CodeBlock(type: .code, content: splittedString)
                        if index < splittedStrings.count - 1 { // for all n-1 elements
                            codeLines.append(splittedCodeBlock)
                            codeSections.append(codeLines)
                            codeLines.removeAll()
                        } else { // for last element
                            codeLines.append(splittedCodeBlock)
                        }
                    }
                case .gap:
                    // "Gap" type has never newline -> append directly to code lines
                    codeLines.append(codeBlock)
                case .output:
                    // "Output" type shall always start a new section
                    codeSections.append(codeLines)
                    codeLines.removeAll()
                    // Parse string of "Output" type for new lines and append sections (except of the last string)
                    let splittedStrings = codeBlock.content.safeNewLineSplit
                    for (index, splittedString) in splittedStrings.enumerated() {
                        let splittedCodeBlock = CodeBlock(type: .output, content: splittedString)
                        if index < splittedStrings.count - 1 { // for all n-1 elements
                            codeLines.append(splittedCodeBlock)
                            codeSections.append(codeLines)
                            codeLines.removeAll()
                        } else { // for last element
                            codeLines.append(splittedCodeBlock)
                        }
                    }
                }
            }
            codeSections.append(codeLines)
            codeLines.removeAll()
            
            return codeSections
        } else {
            return nil
        }
    }
}
struct Choice: Decodable {
    var title: String
    var solution: Bool
}
struct CodeBlock: Decodable {
    var type: CodeType
    var content: String
}
enum CodeType: String, Decodable {
    case code = "code"
    case gap = "gap"
    case output = "output"
}
struct AmselAction: Decodable {
    var type: ActionType
    var parameter: [String]
}
enum ActionType: String, Decodable {
    case print = "print"
    case forward = "forward"
    case left = "left"
    case forwardTillBarrier = "forwardTillBarrier"
}

func loadLessons(from fileName: String = "lessons") -> [Lesson] {
    if let url = Bundle.main.url(forResource: fileName, withExtension: "json") {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode(Lessons.self, from: data)
            return jsonData.lessons
        } catch {
            print("error:\(error)")
        }
    }
    return [] // maybe add error here, but lessons.json should be always valid before publishing
}

struct Users: Codable {
    var users: [User]
    init(_ users: [User]) {
        self.users = users
    }
}
struct User: Codable {
    var id: String
    var name: String
    var passedSections: [String]
}

func loadUsers(from fileName: String = "users") -> [User] {
    // Get url of default users data
    var fileUrl = Bundle.main.url(forResource: fileName, withExtension: "json")
    
    // Check if saved users data is available
    if let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        let fullDocumentDirectoryUrl = documentDirectoryUrl.appendingPathComponent("\(fileName).json")
        
        if FileManager.default.fileExists(atPath: fullDocumentDirectoryUrl.path) {
            fileUrl = fullDocumentDirectoryUrl
//            do {
//                try FileManager.default.removeItem(atPath: fullDocumentDirectoryUrl.path)
//            } catch {
//                print("error:\(error)")
//            }
        }
    }
    
    // Decode and return data
    if let fileUrl = fileUrl {
        do {
            let data = try Data(contentsOf: fileUrl)
            var jsonData = try JSONDecoder().decode(Users.self, from: data)
            // Create new user, if only default user is available
            if jsonData.users.count == 1 {
                jsonData.users.append(jsonData.users[0])
                jsonData.users[1].name = "Custom User"
            }
            return jsonData.users
        } catch {
            print("error:\(error)")
        }
    }
    return [] // maybe add error here, but users.json should be always valid before publishing
}

private func saveUsers(_ users: [User], to fileName: String = "users") {
    if let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        let fileUrl = documentDirectoryUrl.appendingPathComponent("\(fileName).json")
        
        // create a .json file in the Documents folder if needed
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            FileManager.default.createFile(atPath: fileUrl.path, contents: nil, attributes: nil)
        }
        
        // Encode and save data
        do {
            let jsonData = Users(users)
            let data = try JSONEncoder().encode(jsonData)
            try data.write(to: fileUrl)
        } catch {
            print("error:\(error)")
        }
    }
}


func resetUser(userIndex: Int = 1) {
    var users = loadUsers()
    users[userIndex] = users[0]
    saveUsers(users)
}

func userPassedSectionCount(userIndex: Int = 1) -> Int {
    return loadUsers()[userIndex].passedSections.count
}

func userPassedSection(withId uuid: String, userIndex: Int = 1) {
    var users = loadUsers()
    
    users[userIndex].passedSections.append(uuid)
    users[userIndex].passedSections = Array(Set(users[userIndex].passedSections))
    
    saveUsers(users)
}

func userFailedSection(withId uuid: String, userIndex: Int = 1) {
    var users = loadUsers()
    
    users[userIndex].passedSections = users[userIndex].passedSections.filter(){$0 != uuid}
    
    saveUsers(users)
}

func didUserPassSection(withId uuid: String, userIndex: Int = 1) -> Bool {
    let users = loadUsers()
    var didUserPass = false
    
    if users[userIndex].passedSections.contains(uuid) {
        didUserPass = true
    }
    
    return didUserPass
}
