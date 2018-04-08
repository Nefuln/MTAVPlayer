//
//  MTAVPlayerManager.swift
//  MTAVPlayerView
//
//  Created by Nolan on 2018/3/28.
//  Copyright © 2018年 Nolan. All rights reserved.
//

import UIKit
import AVFoundation

public enum MTAVPlayerError: Int {
    case mistakePath = 0
    case failed
    case unknown
}

public protocol MTAVPlayerDelegate: NSObjectProtocol {
    func playFinished()
    func loadProgess(buffer: Float64, duration: Float64)
    func playProgess(current: Float64, duration: Float64)
    func unablePlay(error: MTAVPlayerError)
}

extension MTAVPlayerDelegate {
    public func playFinished() {}
    public func loadProgess(buffer: Float64, duration: Float64) {}
    public func playProgess(current: Float64, duration: Float64) {}
    public func unablePlay(error: MTAVPlayerError) {}
}

public let MTAVPlayerPlayStartNotification = Notification.Name(rawValue: "MTAVPlayerPlayStartNotification")
public let MTAVPlayerPlayPauseNotification = Notification.Name(rawValue: "MTAVPlayerPlayPauseNotification")
public let MTAVPlayerPlayFinishNotification = Notification.Name(rawValue: "MTAVPlayerPlayFinishNotification")

public class MTAVPlayerManager: NSObject {
    
    public static let manager = MTAVPlayerManager()
    
    weak public var delegate: MTAVPlayerDelegate?
    public var playerLayer: AVPlayerLayer?
    public var vedioUrl: String?
    private(set) public var isPlaying: Bool {
        set {
            _isPlaying = newValue
            if newValue == true {
                NotificationCenter.default.post(name: MTAVPlayerPlayStartNotification, object: nil, userInfo: ["vedioUrl" : self.vedioUrl ?? ""])
            }
        }
        
        get {
            return _isPlaying
        }
    }
    
    public var player: AVPlayer = AVPlayer()
    public var duration: Float64 {
        return CMTimeGetSeconds(self.playerItem?.duration ?? CMTime())
    }
    
    fileprivate var playerItem: AVPlayerItem?
    fileprivate var _isPlaying: Bool = false
    fileprivate var _player: AVPlayer?
    fileprivate var playTimeObserver: Any?

    public override init() {
        super.init()
        self.addObservers()
    }
    
    deinit {
        self.removeObservers()
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath != nil else {
            return
        }
        switch keyPath! {
        case "status":
            self.handleObserveValueForStatus(of: object, change: change)
        case "loadedTimeRanges":
            self.handleObserveValueForLoadedTimeRanges(of: object, change: change)
        default:
            break
        }
    }
}

public extension MTAVPlayerManager {
    public func updateNativeVedio(filePath: String, player: AVPlayer? = nil) {
        self.vedioUrl = filePath
        let vedioUrl = URL(fileURLWithPath: filePath)
        let vedioAsset = AVURLAsset(url: vedioUrl)
        self.playerItem = AVPlayerItem(asset: vedioAsset)
        self.addObserversForPlayerItem()
        if player == nil {
            self.player.replaceCurrentItem(with: self.playerItem)
        } else {
            player?.replaceCurrentItem(with: self.playerItem)
        }
    }
    
    public func updateOnlineVeido(url: String, player: AVPlayer? = nil) {
        guard let playUrl = URL(string: url) else {
            self.delegate?.unablePlay(error: .mistakePath)
            return
        }
        self.vedioUrl = url
        self.playerItem = AVPlayerItem(url: playUrl)
        self.addObserversForPlayerItem()
        if player == nil {
            self.player.replaceCurrentItem(with: self.playerItem)
        } else {
            player?.replaceCurrentItem(with: self.playerItem)
        }
    }
    
    public func startPlay(player: AVPlayer? = nil) {
        if player != nil {
            if player! != self.player {
                self.stop()
            }
            self.player = player!
        }
        self.player.play()
        self.isPlaying = true
    }
    
    public func pause(player: AVPlayer? = nil) {
        if player != nil {
            self.player = player!
        }
        self.player.pause()
        self.isPlaying = false
        NotificationCenter.default.post(name: MTAVPlayerPlayPauseNotification, object: nil, userInfo: ["vedioUrl" : self.vedioUrl ?? ""])
    }
    
    public func stop(player: AVPlayer? = nil) {
        if player != nil {
            self.player = player!
        }
        self.player.pause()
        self.isPlaying = false
        self.vedioUrl = nil
        self.playerItem?.seek(to: kCMTimeZero)
        NotificationCenter.default.post(name: MTAVPlayerPlayFinishNotification, object: nil, userInfo: nil)
    }
}

extension MTAVPlayerManager {
    fileprivate func addObservers() {
        self.monitoringPlayProgress()
        NotificationCenter.default.addObserver(self, selector: #selector(MTAVPlayerManager.handleNotificationForPlayFinished), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    fileprivate func addObserversForPlayerItem() {
        self.playerItem?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        self.playerItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
    }
    
    fileprivate func removeObservers() {
        self.playTimeObserver = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleNotificationForPlayFinished() {
        self.isPlaying = false
        self.vedioUrl = nil
        self.playerItem?.seek(to: kCMTimeZero)
        self.delegate?.playFinished()
        NotificationCenter.default.post(name: MTAVPlayerPlayFinishNotification, object: nil, userInfo: nil)
    }
    
    private func monitoringPlayProgress() {
        self.playTimeObserver = self.player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: CMTimeScale(30.0)), queue: DispatchQueue.main) { (time) in
            guard let item = self.playerItem else {
                return
            }
            let currenttime = CMTimeGetSeconds((item.currentTime()))
            self.delegate?.playProgess(current: currenttime, duration: CMTimeGetSeconds(item.duration))
        }
    }
}

extension MTAVPlayerManager {
    fileprivate func handleObserveValueForStatus(of object: Any?, change: [NSKeyValueChangeKey : Any]?) {
        guard let statusValue = change?[NSKeyValueChangeKey.newKey] as? Int else {
            return
        }
        
        /// 获取播放状态
        let status = AVPlayerStatus(rawValue: statusValue) ?? .unknown
        debugPrint("status:: \(status)")
        switch status {
        case .readyToPlay:          //准备播放
            break
        case .failed:               //播放失败
            self.vedioUrl = nil
            self.delegate?.unablePlay(error: .failed)
        case .unknown:              //未知错误
            self.vedioUrl = nil
            self.delegate?.unablePlay(error: .unknown)
        }
    }
    
    fileprivate func handleObserveValueForLoadedTimeRanges(of object: Any?, change: [NSKeyValueChangeKey : Any]?) {
        guard let loadTimeRanges = change?[NSKeyValueChangeKey.newKey] as? [Any] else {
            return
        }
        guard let timeRange = loadTimeRanges.first as? CMTimeRange else {
            return
        }
        let startSeconds = CMTimeGetSeconds(timeRange.start);
        let durationSeconds = CMTimeGetSeconds(timeRange.duration);
        let result = startSeconds + durationSeconds; // 计算总缓冲时间 = start + duration
        debugPrint("\(startSeconds)_\(durationSeconds)_\(result)")
        self.delegate?.loadProgess(buffer: result, duration: self.duration)
    }
}
