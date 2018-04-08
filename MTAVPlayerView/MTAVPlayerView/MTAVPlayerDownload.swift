//
//  MTAVPlayerDownload.swift
//  MTAVPlayerView
//
//  Created by Nolan on 2018/3/29.
//  Copyright © 2018年 Nolan. All rights reserved.
//

import UIKit

public enum MTAVPlayerDownloadErrorType: Int {
    case pathError = 10000
    case downloadError
    case saveError
}

public class MTAVPlayerDownload: NSObject {
    
    public typealias MTAVPlayerProgressBlock = (_ written: Int64, _ total: Int64, _ progress: Double)->Void
    public typealias MTAVPlayerCompletionBlock = (_ isSuccess: Bool, _ error: NSError?)->Void
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        let currentSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        return currentSession
    }()
    
    fileprivate var toPath: String?
    fileprivate var progressBlock: MTAVPlayerProgressBlock?
    fileprivate var completionBlock: MTAVPlayerCompletionBlock?
    fileprivate let errorDomain = "MTAVPlayerDownload"
    
    public func download(url: String, toPath: String?, progress: MTAVPlayerProgressBlock? = nil, completion: MTAVPlayerCompletionBlock?) {
        self.toPath = toPath
        self.progressBlock = progress
        self.completionBlock = completion
        guard let downloadUrl = URL(string: url) else {
            let error = NSError(domain: errorDomain, code: MTAVPlayerDownloadErrorType.pathError.rawValue, userInfo: ["desc" : "文件下载路径无效"])
            self.completionBlock(isSuccess: false, error: error)
            return
        }
        let downloadTask = self.session.downloadTask(with: downloadUrl)
        downloadTask.resume()
    }
}

extension MTAVPlayerDownload: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard self.toPath != nil else {
            let error = NSError(domain: errorDomain, code: MTAVPlayerDownloadErrorType.saveError.rawValue, userInfo: ["desc" : "文件存储路径为空"])
            self.completionBlock(isSuccess: false, error: error)
            return
        }

        do {
            try FileManager.default.moveItem(atPath: location.path, toPath: self.toPath!)
            self.completionBlock(isSuccess: true, error: nil)
        } catch let err as NSError {
            debugPrint(err)
            let error: NSError = NSError(domain: self.errorDomain, code: MTAVPlayerDownloadErrorType.saveError.rawValue, userInfo: ["desc" : "文件存储失败"])
            self.completionBlock(isSuccess: false, error: error)
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard self.progressBlock != nil else {
            return
        }
        let progress: Double = Double(totalBytesWritten)/Double(totalBytesExpectedToWrite)
        self.progressBlock!(totalBytesWritten, totalBytesExpectedToWrite, progress)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error == nil {
            return
        }
        self.completionBlock(isSuccess: false, error: NSError(domain: errorDomain, code: MTAVPlayerDownloadErrorType.downloadError.rawValue, userInfo: ["desc" : "文件下载失败"]))
    }
    
    private func completionBlock(isSuccess: Bool, error: NSError?) {
        guard self.completionBlock != nil else {
            return
        }
        DispatchQueue.main.async {
            self.completionBlock!(isSuccess, error)
            self.completionBlock = nil
        }
    }
}
