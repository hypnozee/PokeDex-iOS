//
//  Item.swift
//  PokeDex
//
//  Created by Razvan Barbu on 15.11.2025.
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
