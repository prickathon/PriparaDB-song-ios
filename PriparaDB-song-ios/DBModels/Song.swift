import Foundation

struct EndpointLives: Codable {
    var live: [Live]
}

struct Live: Codable {
    var episode: Episode
    var team: Team
    var song: Song
    var MD: MakingDrama
    var coordinate: [Coordinate]
}

struct Episode: Codable {
    var series: String
    var number: Int
}

struct Song: Codable {
    var title: String
    var team: Team
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
    var chara: String
    var name: String
    var brand: String?
}
