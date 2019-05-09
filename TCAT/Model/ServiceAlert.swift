//
//  ServiceAlert.swift
//  TCAT
//
//  Created by Omar Rasheed on 4/19/19.
//  Copyright © 2019 cuappdev. All rights reserved.
//

import UIKit

struct ServiceAlert: Codable {
    var id: Int
    var message: String
    var fromDate: String
    var toDate: String
    var fromTime: String
    var toTime: String
    var priority: Int
    var daysOfWeek: String
    var routes: [Int]
    var signs: [Int]
    var channelMessages: [ChannelMessage]
}

struct ChannelMessage: Codable {
    var ChannelId: Int
    var message: String
}
