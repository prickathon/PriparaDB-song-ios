import Foundation

struct EndpointLives: Codable {
    var lives: [Live]
}

struct Live: Codable, Equatable {
    var episode: Episode
    var team: Team
    var song: Song
    var MD: MakingDrama
    var coordinate: [Coordinate]

    static func == (lhs: Live, rhs: Live) -> Bool {
        return lhs.episode == rhs.episode && lhs.song == rhs.song
    }
}

struct Episode: Codable, Equatable {
    var series: String
    var number: Int
    var title: String?

    static func == (lhs: Episode, rhs: Episode) -> Bool {
        return lhs.series == rhs.series && lhs.number == rhs.number
    }
}

struct Song: Codable, Equatable {
    var title: String
    var team: Team

    static func == (lhs: Song, rhs: Song) -> Bool {
        return lhs.title == rhs.title
    }
}

struct Team: Codable {
    var name: String?
    var members: [String]
}

struct MakingDrama: Codable {
    var title: String?
    var team: Team
}

struct Coordinate: Codable {
    var character: String
    var name: String
    var brand: String?
}
