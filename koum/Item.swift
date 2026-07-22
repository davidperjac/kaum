//
//  Item.swift
//  koum
//
//  Created by David Perez on 7/22/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
