//
//  YoutubePlaylistModel.swift
//  Example
//
//  Created by zerolive on 2022/03/13.
//  Copyright © 2022 Moayad Al kouz. All rights reserved.
//

import Foundation

enum DownloadingState {
    case FINISHED, FAILED, DOWNLOADING
}

protocol YoutubePlaylistDownloaderDelegate {
    func downloadState(state: DownloadingState)
}

struct YoutubePlayListResult {
    var playlistId: String?
    var list: [YoutubeVideLists]?
}

struct YoutubeVideLists {
    var videoIds: String
    var titles: String
    var thumbnail: String
}

struct YoutubePlaylistResourceIdData: Decodable {
    let kind: String
    let videoId: String
    
    enum CodingKeys: String, CodingKey {
        case kind
        case videoId
    }
}

struct YoutubePlaylistThumbnailData: Decodable {
    let url: String
    let width: Int
    let height: Int
    
    enum CodingKeys: String, CodingKey {
        case url
        case width
        case height
    }
}

struct YoutubePlaylistThumbnails: Decodable {
    let defaultVal: YoutubePlaylistThumbnailData?
    let medium: YoutubePlaylistThumbnailData?
    let high: YoutubePlaylistThumbnailData?
    let standard: YoutubePlaylistThumbnailData?
    let maxres: YoutubePlaylistThumbnailData?
    
    enum CodingKeys: String, CodingKey {
        case defaultVal = "default"
        case medium
        case high
        case standard
        case maxres
    }
}

struct YoutubePlaylistSnippets: Decodable {
    let publishedAt: String
    let channelId: String
    let title: String
    let thumbnails: YoutubePlaylistThumbnails
    let channelTitle: String
    let playlistId: String
    let position: Int
    let resourceId: YoutubePlaylistResourceIdData
    let videoOwnerChannelTitle: String?
    let videoOwnerChannelId: String?
    
    enum CodingKeys: String, CodingKey {
        case publishedAt
        case channelId
        case title
        case thumbnails
        case channelTitle
        case playlistId
        case position
        case resourceId
        case videoOwnerChannelTitle
        case videoOwnerChannelId
    }
}

struct YoutubePlayListItem: Decodable {
    let kind: String
    let etag: String
    let id: String
    let snippet: YoutubePlaylistSnippets
    
    enum CodingKeys: String, CodingKey {
        case kind
        case etag
        case id
        case snippet
    }
}

struct YoutubePlaylistPageInfoData: Decodable {
    let totalResults: Int
    let resultsPerPage: Int
    
    enum CodingKeys: String, CodingKey {
        case totalResults
        case resultsPerPage
    }
}

struct YoutubePlaylistDataRoot: Decodable {
    let kind: String
    let etag: String
    let nextPageToken: String?
    let items: [YoutubePlayListItem]
    let pageInfo: YoutubePlaylistPageInfoData
    
    enum CodingKeys: String, CodingKey {
        case kind
        case etag
        case nextPageToken
        case items
        case pageInfo
    }
}
