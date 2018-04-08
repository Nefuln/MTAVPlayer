//
//  ViewController.swift
//  MTAVPlayerDemo
//
//  Created by Nolan on 2018/3/28.
//  Copyright © 2018年 Nolan. All rights reserved.
//

import UIKit
import MTAVPlayerView

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }

    let playView1 = MTAVPlayerView()
    let playView2 = MTAVPlayerView()
}

extension ViewController {
    fileprivate func setupUI() {
        let bendiBtn = UIButton(type: .custom)
        bendiBtn.setTitle("本地视频", for: .normal)
        bendiBtn.setTitleColor(UIColor.blue, for: .normal)
        bendiBtn.backgroundColor = UIColor.yellow
        bendiBtn.frame = CGRect(x: 100, y: 200, width: 100, height: 50)
        bendiBtn.addTarget(self, action: #selector(ViewController.handlePlayBendi), for: .touchUpInside)
        
        let onlineBtn = UIButton(type: .custom)
        onlineBtn.setTitle("在线视频", for: .normal)
        onlineBtn.setTitleColor(UIColor.blue, for: .normal)
        onlineBtn.backgroundColor = UIColor.yellow
        onlineBtn.frame = CGRect(x: 100, y: 300, width: 100, height: 50)
        onlineBtn.addTarget(self, action: #selector(ViewController.handlePlayOnline), for: .touchUpInside)
        
        self.playView1.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 200)
        self.playView2.frame = CGRect(x: 0, y: 250, width: self.view.frame.width, height: 200)
        
        self.view.addSubview(self.playView1)
        self.view.addSubview(self.playView2)
        self.view.addSubview(bendiBtn)
        self.view.addSubview(onlineBtn)
        
        debugPrint("播放本地视频")
        let filePath = Bundle.main.path(forResource: "test", ofType: "mp4")
        self.playView1.updateNativeVedio(filePath: filePath!)

        let url = "http://file.battleofballs.com/heyhey_238776_1510153379_86591.mp4"
        self.playView2.updateOnlineVedio(url: url)
    }
}

extension ViewController {
    @objc fileprivate func handlePlayBendi() {
        self.playView1.startPlay()
    }
    
    @objc fileprivate func handlePlayOnline() {
        debugPrint("播放在线视频")
        let url = "http://file.battleofballs.com/heyhey_238776_1510153379_86591.mp4"
        let storage = MTAVPlayerStorage(fileUrl: url)
        if storage.isExists {
//            self.playView2.startPlayNativeVedio(filePath: storage.filePath)
            self.playView2.updateNativeVedio(filePath: storage.filePath)
            self.playView2.startPlay()
        } else {
            storage.download(progress: { (written, total, progress) in
                debugPrint("written: \(written); total: \(total); progress: \(progress)")
            }, completion: { (isSuccess, error) in
                guard isSuccess == true else {
                    debugPrint("下载失败，稍候重试")
                    return
                }
                self.playView2.startPlay()
            })
        }
    }
}

