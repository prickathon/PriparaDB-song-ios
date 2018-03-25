import UIKit
import NorthLayout
import Ikemen
import ReactiveSwift
import ReactiveCocoa
import Differ

final class ViewController: UITableViewController {
    private let viewModel = ViewModel()
    private class ViewModel {
        let lives: MutableProperty<[Live]>
        private(set) lazy var songs: Property<[Song]> = Property<[Live]>(capturing: lives).map {$0.compactMap {$0.song}}

        init() {
            let d = try! Data(contentsOf: Bundle.main.url(forResource: "main", withExtension: "json")!)
            lives = .init(try! JSONDecoder().decode(EndpointLives.self, from: d).live)
        }
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        title = "Pripara DB"
    }
    required init?(coder aDecoder: NSCoder) {fatalError()}

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(SongCell.self, forCellReuseIdentifier: String(describing: SongCell.self))

        viewModel.songs.producer
            .combinePrevious([]).startWithValues {[unowned self] a, b in
                self.tableView.animateRowChanges(oldData: a.map {$0.title}, newData: b.map {$0.title})
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.songs.value.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SongCell.self), for: indexPath) as! SongCell
        let s = viewModel.songs.value[indexPath.row]
        cell.setSong(s)
        return cell
    }
}

final class SongCell: UITableViewCell {
    let titleLabel = UILabel() ※ {_ in
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let autolayout = northLayoutFormat([:], ["title": titleLabel])
        autolayout("H:||[title]||")
        autolayout("V:||[title]||")
    }
    required init?(coder aDecoder: NSCoder) {fatalError()}

    func setSong(_ song: Song) {
        titleLabel.text = song.title
    }
}
