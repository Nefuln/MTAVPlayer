//
//  MTAVPlayerView.swift
//  MTAVPlayerView
//
//  Created by Nolan on 2018/3/28.
//  Copyright © 2018年 Nolan. All rights reserved.
//

import UIKit
import AVFoundation

public class MTAVPlayerView: UIView {
    
    weak public var delegate: MTAVPlayerDelegate?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.playerLayer?.frame = self.bounds
    }
    
    fileprivate var playerLayer: AVPlayerLayer?
    fileprivate var vedioUrl: String?
    fileprivate var player: AVPlayer = AVPlayer()
    fileprivate let playerMgr = MTAVPlayerManager()
    public var isPlaying: Bool {
        return MTAVPlayerManager.manager.isPlaying && MTAVPlayerManager.manager.vedioUrl == self.vedioUrl
    }
}

public extension MTAVPlayerView {
    public func updateNativeVedio(filePath: String?) {
        guard filePath != nil else {
            return
        }
        self.vedioUrl = filePath
        self.playerMgr.delegate = self
        self.playerMgr.updateNativeVedio(filePath: filePath!, player: self.player)
    }
    
    public func updateOnlineVedio(url: String?) {
        guard url != nil else {
            return
        }
        self.vedioUrl = url
        self.playerMgr.delegate = self
        self.playerMgr.updateOnlineVeido(url: url!, player: self.player)
    }
    
    public func startPlay() {
        MTAVPlayerManager.manager.startPlay(player: self.player)
    }
    
    public func stopPlay() {
        self.playerMgr.delegate = nil
        MTAVPlayerManager.manager.stop(player: self.player)
    }
}

extension MTAVPlayerView {
    fileprivate func setupUI() {
        self.playerLayer = AVPlayerLayer(player: self.player)
        self.playerLayer?.frame = self.bounds
        self.layer.addSublayer(self.playerLayer!)
    }
}

extension MTAVPlayerView: MTAVPlayerDelegate {
    public func playFinished() {
//        debugPrint("播放完成")
        self.delegate?.playFinished()
    }
    
    public func loadProgess(buffer: Float64, duration: Float64) {
//        debugPrint("加载进度: \(buffer)/\(duration)")
        self.delegate?.loadProgess(buffer: buffer, duration: duration)
    }
    
    public func playProgess(current: Float64, duration: Float64) {
//        debugPrint("播放进度: \(current)/\(duration)")
        self.delegate?.playProgess(current: current, duration: duration)
    }
    
    public func unablePlay(error: MTAVPlayerError) {
//        debugPrint(error)
        self.delegate?.unablePlay(error: error)
    }
}
