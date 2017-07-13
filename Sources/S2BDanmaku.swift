//
//  S2BDanmaku.swift
//  Srt2BilibiliKit
//
//  Created by Apollo Zhu on 7/8/17.
//  Copyright © 2017 WWITDC. All rights reserved.
//

import Foundation

public class S2BDanmaku {
    
    public init(_ danmaku: String, cid: Int, playTime: TimeInterval, config: Config) {
        self.cid = cid
        self.content = danmaku
        self.playTime = playTime
        self.config = config
    }
    
    public convenience init(_ danmaku: String, cid: Int, playTime: TimeInterval, rgb color: Int? = nil, fontSize: Config.FontSize? = nil, mode: Config.Mode? = nil, pool: Config.Pool? = nil) {
        self.init(danmaku, cid: cid, playTime: playTime,
                  config: Config(rgb: color, fontSize: fontSize, mode: mode, pool: pool))
    }
    
    public let cid: Int
    public let content: String
    public let playTime: TimeInterval
    public let config: Config
    
    public struct Config {
        public let color: Int
        public let fontSize: FontSize
        public let mode: Mode
        public let pool: Pool
        
        public static let `default` = Config()
        
        public init(rgb color: Int? = nil, fontSize: FontSize? = nil, mode: Mode? = nil, pool: Pool? = nil) {
            self.color = max(min(color ?? 0xFFFFFF, 0xFFFFFF), 0)
            self.fontSize = fontSize ?? .medium
            self.mode = mode ?? .bottom
            self.pool = pool ?? .normal
        }
        
        public enum Mode: Int {
            case normal = 1
            case bottom = 4
            case top = 5
            case reversed = 6
            case special = 7
            case advanced = 9
        }
        
        public enum Pool: Int {
            case normal = 0, subtitle, special
        }
        
        public enum FontSize: RawRepresentable {
            case small, medium, large
            case custom(Int)
            
            public typealias RawType = Int
            
            public var rawValue: Int {
                switch self {
                case .small:
                    return 18
                case .medium:
                    return 25
                case .large:
                    return 36
                case .custom(let fontSize):
                    return fontSize
                }
            }
            
            public init?(rawValue: Int) {
                switch rawValue {
                case FontSize.small.rawValue:
                    self = .small
                case FontSize.medium.rawValue:
                    self = .medium
                case FontSize.large.rawValue:
                    self = .large
                default:
                    self = .custom(rawValue)
                }
            }
        }
    }
}