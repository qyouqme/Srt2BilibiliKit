//
//  main.swift
//  Srt2BilibiliKit-cli
//
//  Created by Apollo Zhu on 7/9/17.
//  Copyright © 2017 WWITDC. All rights reserved.
//

import Foundation

// MARK: Usage/Help

let usage = """

usage: s2bkit [-h] -a avNumber -s subRipFile [-p 1] [-c ./bilicookies] [-o 16777215...] [-f 25...] [-m 4...] [-l 0...] [-w 4]

-h (optional)
\tPrint the usage

-a aid (required)
\tThe av number to post to

-s srt (required)
\tThe srt file you to post.

-p page (default 1)
\tThe page/part number.

-c cookie (default ./bilicookies)
\tThe path to the cookie file (required)
\tRetrieved using https://github.com/dantmnf/biliupload/blob/master/getcookie.py, has structure similar to
\t
\tDedeUserID=xx;DedeUserID__ckMd5=xx;SESSDATA=xx

-o color (default 16777215)
\tThe color of danmaku, represented in dec(16777215) or hex(0XFFFFFF).

-f fontSize (default 25)
\tThe font size of danmaku.

-m mode (default 4)
\tThe mode of danmaku.
\t1: Normal
\t4: Bottom
\t5: Top
\t6: Reversed
\t7: Special
\t9: Advanced

-l pool (default 0)
\tThe Danmaku Pool to use.
\t0: Normal
\t1: Subtitle (Suggested if you own the video)
\t2: Special

-w delay (default 4)
\tCool time in seconds (time to wait before posting the next one).
\tNumber smaller than the default may result in ban or failure.
"""

func exitAfterPrintingUsage() -> Never { print(usage);exit(0) }

// MARK: Parse

var aid: Int?
var srt: String?
var page = 1
var cookie: String? = nil
var color = [Int]()
var fontSize = [Int]()
var mode = [Int]()
var pool = [Int]()
var delay = S2BEmitter.bilibiliDelay

#if DEBUG
let arguments = ["s2bkit", "-l", "1", "-f", "18", "25", "-a", "8997583", "-s", "/Users/Apollonian/Documents/Git-Repo/Developing-iOS-10-Apps-with-Swift/subtitles/3. More Swift and the Foundation Framework.srt", "-c", "/Users/Apollonian/bilicookies"]
#else
let arguments = CommandLine.arguments
#endif
guard arguments.count > 1 else { exitAfterPrintingUsage() }
var index = 1

func hasNext() -> Bool {
    return index < arguments.count && !arguments[index].hasPrefix("-")
}

func next() -> String {
    defer { index += 1 }
    return arguments[index]
}

while index < arguments.count {
    let cur = arguments[index].lowercased()
    index += 1
    if ["-h", "-?", "--help"].contains(cur) { exitAfterPrintingUsage() }
    if index == arguments.count { break }
    if !hasNext() { continue }
    switch cur {
    case "-a", "--av", "--aid":
        aid = Int(next())
    case "-s", "--srt", "--subrip":
        srt = next()
    case "-p", "--page", "--part":
        page = Int(next()) ?? page
    case "-c", "--cookie":
        cookie = next()
    case "-o", "--color":
        while hasNext() {
            var option = next()
            if option.hasPrefix("0x") { option.removeFirst(2) }
            color.append(Int(option) ?? Int(option, radix: 16) ?? 0xffffff)
        }
    case "-f", "--font", "--size", "--fontsize":
        while hasNext() {
            fontSize.append(Int(next()) ?? 25)
        }
    case "-m", "--mode":
        while hasNext() {
            mode.append(Int(next()) ?? 4)
        }
    case "-l", "--pool":
        while hasNext() {
            pool.append(Int(next()) ?? 0)
        }
    case "-w", "--cooltime", "--delay":
        delay = Double(next()) ?? delay
    default:
        break
    }
}

// MARK: Check Required

guard let aid = aid else { fatalError("AV number is REQUIRED") }
guard let path = srt, var subRip = S2BSubRipFile(path: path) else { fatalError("Path to srt file is REQUIRED") }
guard let cookie = S2BCookie(path: cookie) else { fatalError("Unable to load cookie") }

// MARK: Zip Configs

if color.count == 0 { color = [0xffffff] }
if fontSize.count == 0 { fontSize = [25] }
if mode.count == 0 { mode = [4] }
if pool.count == 0 { pool = [0] }

func gcd(_ m: Int, _ n: Int) -> Int { return n == 0 ? m : gcd(n, m % n) }
func lcm(_ m: Int, _ n: Int) -> Int { return m * n / gcd(m, n) }

let configCount = lcm(lcm(lcm(color.count, fontSize.count), mode.count), pool.count)
color = [[Int]](repeatElement(color, count: configCount / color.count)).flatMap { $0 }
fontSize = [[Int]](repeatElement(fontSize, count: configCount / fontSize.count)).flatMap { $0 }
mode = [[Int]](repeatElement(mode, count: configCount / mode.count)).flatMap { $0 }
pool = [[Int]](repeatElement(pool, count: configCount / pool.count)).flatMap { $0 }
let configs = zip(zip(color, fontSize), zip(mode, pool)).map {
    S2BDanmaku.Config(rgb: $0.0.0,
                      fontSize: S2BDanmaku.Config.FontSize(rawValue: $0.0.1),
                      mode: S2BDanmaku.Config.Mode(rawValue: $0.1.0),
                      pool: S2BDanmaku.Config.Pool(rawValue: $0.1.1))
}

// MARK: Post Danmaku

S2BVideo(av: aid).page(page) {
    guard let cid = $0?.cid, let title = $0?.pageName else { fatalError("Unable to fetch video") }
    print("Posting to \(title)")
    let emitter = S2BEmitter(cookie: cookie, delay: delay)
    emitter.post(srt: subRip, toCID: cid, configs: configs) {
        exit(0)
    }
}

// MARK: Wait

// Enable indefinite execution to wait for asynchronous operation
while true { }
