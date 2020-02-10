//
//  Extensions.swift
//  Amsel
//
//  Created by Anja on 04.01.20.
//  Copyright © 2020 Anja. All rights reserved.
//

import UIKit

extension String {
    var htmlToAttributedString: NSAttributedString? {
        let modifiedString = String(format:"<span style=\"font-family: '-apple-system', 'HelveticaNeue'; font-size: 16; font-weight: 300\">%@</span>", self)
        
        guard let data = modifiedString.data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
    var safeNewLineSplit: [String] {
        let uuidBackslash = UUID().uuidString
        var backslashEscapedString = self.replacingOccurrences(of: "\\\\", with: uuidBackslash)
        
        let uuidTrailing = UUID().uuidString
        backslashEscapedString += uuidTrailing
        
        var lines = backslashEscapedString.components(separatedBy: CharacterSet.newlines)
        
        for (index, line) in lines.enumerated() {
            var originalLine = line.replacingOccurrences(of: uuidBackslash, with: "\\\\")
            originalLine = originalLine.replacingOccurrences(of: uuidTrailing, with: "")
            lines[index] = originalLine
        }
        
        return lines
    }
}
