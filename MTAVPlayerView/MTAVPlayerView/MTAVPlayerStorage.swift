//
//  MTAVPlayerStorage.swift
//  MTAVPlayerView
//
//  Created by Nolan on 2018/3/29.
//  Copyright © 2018年 Nolan. All rights reserved.
//

import UIKit

public class MTAVPlayerStorage: NSObject {
    
    required public init(fileUrl: String) {
        super.init()
        self.fileUrl = fileUrl
    }
    
    /// Library/Cache路径
    public var cachePath: String {
        set {
            _cachePath = newValue
        }
        
        get {
            if _cachePath != nil {
                return _cachePath!
            }
            if !FileManager.default.fileExists(atPath: self.defaultCachePath) {
                try! FileManager.default.createDirectory(atPath: self.defaultCachePath, withIntermediateDirectories: true, attributes: nil)
            }
            return self.defaultCachePath
        }
    }
    
    fileprivate var _cachePath: String?
    fileprivate let defaultCachePath: String = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first! + "/MTVedio"
    
    /// 需要持久化的文件URL
    fileprivate var fileUrl: String?
    
    /// 根据文件URL生成文件存储路径
    public var filePath: String? {
        return self.fileUrl != nil ? (self.cachePath as NSString).appendingPathComponent((self.fileUrl! as NSString).lastPathComponent) : nil
    }
    
    /// 文件是否持久化
    public var isExists: Bool {
        guard self.filePath != nil else {
            return false
        }
        return FileManager.default.fileExists(atPath: self.filePath!)

    }
    
    /// 下载文件
    ///
    /// - Parameter completion: 下载成功
    public func download(progress: MTAVPlayerDownload.MTAVPlayerProgressBlock? = nil, completion: MTAVPlayerDownload.MTAVPlayerCompletionBlock?) {
        guard self.fileUrl != nil else {
            return
        }
        MTAVPlayerDownload().download(url: self.fileUrl!, toPath: self.filePath, progress: progress, completion: completion)
    }

}
