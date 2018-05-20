import UIKit
import Ikemen
import Eureka
import ReactiveSwift
import ReactiveCocoa
import SVProgressHUD
import BrightFutures
import Result

private let livesURL = URL(string: "https://script.google.com/macros/s/AKfycbwWHf9CWY1cH7qe7wyieLkXzbxgIaglJzasyZqomwavm000res/exec")!
private let dbFileURL = URL(fileURLWithPath: NSHomeDirectory())
    .appendingPathComponent("Library")
    .appendingPathComponent("dbMaster.json")

struct DBMaster: Codable {
    static let shared: MutableProperty<DBMaster?> = .init(try? JSONDecoder().decode(DBMaster.self, from: (try? Data(contentsOf: dbFileURL)) ?? Data()))
    static let sharedLives: Property<EndpointLives> = Property<DBMaster?>(capturing: shared)
        .map {$0?.lives ?? (try! JSONDecoder().decode(EndpointLives.self, from: try! Data(contentsOf: Bundle.main.url(forResource: "main", withExtension: "json")!)))}

    var updatedAt: Date
    var lives: EndpointLives
}

final class SettingsViewController: FormViewController {
    let dbMaster = DBMaster.shared

    private lazy var dbLastUpdatedRow: LabelRow = .init() {
        $0.title = "最終更新"
    }
    private lazy var dbUpdateButtonRow: ButtonRow = .init() {
        $0.title = "DB更新"
        $0.onCellSelection {[unowned self] _, _ in self.updateDB()}
    }
    private lazy var dbViewerButtonRow: ButtonRow = .init() {
        $0.title = "Firebase DB Viewer"
        $0.onCellSelection {[unowned self] _, _ in self.showDBViewer()}
    }

    init() {
        super.init(style: .grouped)
        title = "Settings"

        form +++ Section()
        <<< dbLastUpdatedRow
        <<< dbUpdateButtonRow
        +++ Section()
        <<< dbViewerButtonRow
    }
    required init?(coder aDecoder: NSCoder) {fatalError()}

    override func viewDidLoad() {
        super.viewDidLoad()

        dbMaster.producer.take(duringLifetimeOf: self).startWithValues { [unowned self] m in
            let df = DateFormatter()
            df.dateStyle = .medium
            df.timeStyle = .medium
            self.dbLastUpdatedRow.value = m.map {df.string(from: $0.updatedAt)} ?? "ローカル初期データ"
            self.form.first?.reload()
        }
    }

    func updateDB() {
        SVProgressHUD.show()
        fetch(url: livesURL)
            .flatMap { d -> Result<DBMaster, Error> in
                do {
                    let lives = try JSONDecoder().decode(EndpointLives.self, from: d)
                    return .success(DBMaster(updatedAt: Date(), lives: lives))
                } catch {
                    return .failure(.invalidData(error as NSError))
                }
            }
            .flatMap { m -> Result<DBMaster, Error> in
                do {
                    try JSONEncoder().encode(m).write(to: dbFileURL)
                    return .success(m)
                } catch {
                    return .failure(.cannotCache(error as NSError))
                }
            }
            .onComplete {_ in SVProgressHUD.dismiss()}
            .onSuccess { m in
                self.dbMaster.value = m
            }.onFailure { e in
                let ac = UIAlertController(title: "更新失敗しました", message: "\(String(describing: e))", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(ac, animated: true)
        }
    }

    func showDBViewer() {
        show(EpisodesViewController(), sender: nil)
    }

    enum Error: Swift.Error {
        case noData
        case invalidStatus(Int)
        case urlError(NSError)
        case invalidData(NSError)
        case cannotCache(NSError)
    }

    func fetch(url: URL) -> Future<Data, Error> {
        return .init { resolve in
            var req = URLRequest(url: url)
            req.cachePolicy = .reloadIgnoringLocalCacheData
            URLSession.shared.dataTask(with: req) { (data, response, error) in
                guard let data = data, let response = response as? HTTPURLResponse else { return resolve(.failure(.noData)) }
                guard response.statusCode == 200 else { return resolve(.failure(.invalidStatus(response.statusCode))) }
                if let error = error { return resolve(.failure(.urlError(error as NSError))) }
                resolve(.success(data))
            }.resume()
        }
    }
}
