//
//  YoutubePlaylistDownloader.swift
//  Example
//
//  Created by zerolive on 2022/03/13.
//  Copyright © 2022 Moayad Al kouz. All rights reserved.
//

import Foundation
import Alamofire


class YoutubePlaylistDownloader {
    
    var vList = [YoutubeVideLists]()
    var pList = YoutubePlayListResult(playlistId: nil, list: nil)
    
    let APIKEY = "GET IT FROM GOOGLE"
    var apiURL = "https://www.googleapis.com/youtube/v3/playlistItems?key=" + APIKEY + "&part=snippet&maxResults=50&playlistId="
    
    var delegate: YoutubePlaylistDownloaderDelegate? = nil
    
    var playlistId: String = ""{
        didSet{
            if !playlistId.isEmpty{
                requestPlaylist()
            }
            
        }
    }
    
    private func getThumbnails(data: YoutubePlaylistThumbnails) -> String {
        if data.maxres != nil {
            return data.maxres!.url
        }
        
        if data.high != nil {
            return data.high!.url
        }
        
        if data.standard != nil {
            return data.standard!.url
        }
        
        if data.medium != nil {
            return data.medium!.url
        }
        
        if data.defaultVal != nil {
            return data.defaultVal!.url
        }
        
        return "N/A"
    }
    
    private func requestPlaylist() {
        
        self.vList.removeAll()
        
        let url = apiURL + playlistId
        AF.request(url).responseDecodable(of: YoutubePlaylistDataRoot.self) { response in
            switch response.result {
            case .success:
                guard let data = response.value else {
                    Log.print("[requestPlaylist] Can't get value")
                    self.delegate?.downloadState(state: DownloadingState.FAILED)
                    return
                }
                var k = 0
                for i in 0..<data.items.count {
                    // Ignore deleted video
                    if data.items[i].snippet.title == "Deleted video"
                        || data.items[i].snippet.title == "Private video" {
                        k += 1
                        continue
                    }
                    
                    let list = YoutubeVideLists(videoIds: data.items[i].snippet.resourceId.videoId, titles: data.items[i].snippet.title, thumbnail: self.getThumbnails(data: data.items[i].snippet.thumbnails) )
                    self.vList.insert(list, at: i-k)
                }
                self.pList.playlistId = self.playlistId
                self.pList.list = self.vList
                guard let list = self.pList.list else {
                    self.delegate?.downloadState(state: DownloadingState.FAILED)
                    return
                }

                // check if it need more page
                guard let token = data.nextPageToken else {
                    for i in 0..<list.count {
                        Log.print("[\(i)] videoId: \(list[i].videoIds) title: \(list[i].titles) img: \(list[i].thumbnail)")
                    }
                    self.delegate?.downloadState(state: DownloadingState.FINISHED)
                    Log.print("request Finish")
                    return
                }
                
                self.requestPlaylistMore(token: token, idx: list.count)
                
            case .failure(let error):
                self.delegate?.downloadState(state: DownloadingState.FAILED)
                Log.print("Error: \(error)")
                return
            }
        }
    }
    
    private func requestPlaylistMore(token: String, idx: Int) {
        let url = apiURL + playlistId + "&pageToken=" + token

        AF.request(url).responseDecodable(of: YoutubePlaylistDataRoot.self) { response in
            switch response.result {
            case .success:
                guard let data = response.value else {
                    Log.print("[requestPlaylist] Can't get value")
                    self.delegate?.downloadState(state: DownloadingState.FAILED)
                    return
                }
                var k = 0
                for i in idx..<idx+data.items.count {
                    if data.items[i-idx].snippet.title == "Deleted video"
                        || data.items[i-idx].snippet.title == "Private video" {
                        k += 1
                        continue
                    }
                    let list = YoutubeVideLists(videoIds: data.items[i-idx].snippet.resourceId.videoId, titles: data.items[i-idx].snippet.title, thumbnail: self.getThumbnails(data: data.items[i-idx].snippet.thumbnails) )
                    self.vList.insert(list, at: i-k)
                }
                self.pList.playlistId = self.playlistId
                self.pList.list = self.vList
                guard let list = self.pList.list else {
                    self.delegate?.downloadState(state: DownloadingState.FAILED)
                    return
                }
                
                // check if it need more page
                guard let token = data.nextPageToken else {
                    for i in 0..<list.count {
                        Log.print("[\(i)] videoId: \(list[i].videoIds) title: \(list[i].titles) img: \(list[i].thumbnail)")
                    }
                    self.delegate?.downloadState(state: DownloadingState.FINISHED)
                    Log.print("request Finish")
                    return
                }
                
                self.requestPlaylistMore(token: token, idx: list.count)
                
            case .failure(let error):
                self.delegate?.downloadState(state: DownloadingState.FAILED)
                Log.print("Error: \(error)")
                return
            }
        }
    }
}
