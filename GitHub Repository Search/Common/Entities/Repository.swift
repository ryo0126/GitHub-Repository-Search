//
//  Repository.swift
//  GitHub Repository Search
//
//  Created by Ryo on 2021/09/29.
//

/// GitHubのレポジトリ
public struct Repository : Codable {

    private enum CodingKeys : String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case owner
        case htmlUrl = "html_url"
        case description
    }

    public var id: Int64
    public var name: String
    public var fullName: String
    public var owner: Owner
    public var htmlUrl: String
    public var description: String?
}

/// GitHubのレポジトリオーナー
public struct Owner : Codable {

    public var login: String
    public var id: Int64
}
