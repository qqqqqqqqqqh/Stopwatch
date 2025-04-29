//
//  Untitled.swift
//  testMVVM
//
//  Created by colin.qin on 2025/4/28.
//

import Foundation

class Stopwatch: NSObject {
    var counter: Double
    var timer: Timer
    
    override init() {
        counter = 0.0
        timer = Timer()
    }
}
