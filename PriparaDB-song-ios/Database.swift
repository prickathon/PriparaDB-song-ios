import Foundation
import FirebaseDatabase
import CodableFirebase
import Result

final class Database {
    static let shared = Database()
    let ref = FirebaseDatabase.Database.database().reference()

    private init() {
    }

    private func observe<T: Decodable>(root: String, observe: @escaping (Result<T, NSError>) -> Void) {
        Database.shared.ref.child(root).observe(.value) { snapshot in
            guard let value = snapshot.value else { return }
            do {
                let nodes = try FirebaseDecoder().decode(T.self, from: value)
                observe(.success(nodes))
            } catch {
                observe(.failure(error as NSError))
            }
        }
    }

    private func observe<T: Decodable>(root: String, observe: @escaping (Result<[T], NSError>) -> Void) {
        self.observe(root: root) { (result: Result<[String: T], NSError>) in
            result.map {Array($0.values)}
                .analysis(ifSuccess: {observe(.success($0))},
                          ifFailure: {observe(.failure($0))})
        }
    }

    func episodes(observe: @escaping (Result<[Episode], NSError>) -> Void) {
        self.observe(root: "episodes", observe: observe)
    }

    func series(observe: @escaping (Result<[Series], NSError>) -> Void) {
        self.observe(root: "series", observe: observe)
    }

    func series(key: String, observe: @escaping (Result<Series?, NSError>) -> Void) {
        self.observe(root: "series/\(key)", observe: observe)
    }
}
