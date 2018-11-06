import Foundation
import FirebaseDatabase
import CodableFirebase
import ReactiveCocoa
import ReactiveSwift
import BigDiffer
import Ikemen

struct SeriesSection: BigDiffableSection, RandomAccessCollection {
    var series: Series
    var episodes: [Episode]

    // NOTE: fast index is provided by conforming RandomAccessCollection
    var startIndex: Int {return episodes.startIndex}
    var endIndex: Int {return episodes.endIndex}
    func index(after i: Int) -> Int {return i + 1}
    subscript(position: Int) -> Episode {return episodes[position]}

    var diffIdentifier: AnyHashable {return series.diffIdentifier}
}

final class EpisodesViewController: UITableViewController {
    let viewmodel = ViewModel()
    class ViewModel {
        let series: MutableProperty<[SeriesSection]>
        var errors: MutableProperty<[NSError]>

        init() {
            series = .init([])
            errors = .init([])
        }

        func observe() {
            Database.shared.episodes { [weak self] r in
                guard let `self` = self else { return }
                switch r {
                case .success(let episodes):
                    let grouped: [SeriesSection] = episodes.reduce(into: []) { result, next in
                        if let i = (result.index {$0.series.name == next.series}) {
                            result[i] = SeriesSection(series: Series(name: next.series, start_at: nil, end_at: nil),
                                                      episodes: (result[i].episodes + [next]).sorted {$0.number < $1.number})
                        } else {
                            result.append(SeriesSection(series: Series(name: next.series, start_at: nil, end_at: nil), episodes: [next]))
                        }
                    }
                    self.series.value = grouped.sorted {$0.series.name < $1.series.name}
                case .failure(let error):
                    self.errors.value.append(error as NSError)
                }
            }
        }
    }

    init() {
        super.init(style: .grouped)
    }
    required init?(coder aDecoder: NSCoder) {fatalError()}

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(EpisodeCell.self, forCellReuseIdentifier: String(describing: EpisodeCell.self))

        viewmodel.series.producer.combinePrevious().startWithValues { [unowned self] old, new in
            self.tableView.reloadUsingBigDiff(old: old, new: new)
        }

        viewmodel.errors.signal.observeValues { [unowned self] error in
            let ac = UIAlertController(title: "decode error", message: String(describing: error), preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(ac, animated: true, completion: nil)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewmodel.observe()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewmodel.series.value.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let key = viewmodel.series.value[section].series.name
        Database.shared.series(key: key) { [weak self] r in
            guard let `self` = self, let value = r.value, let series = value else { return }
            self.viewmodel.series.value[section].series = series
        }
        return key
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewmodel.series.value[section].episodes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: EpisodeCell.self), for: indexPath) as! EpisodeCell
        cell.configure(viewmodel.series.value[indexPath.section].episodes[indexPath.row])
        return cell
    }
}

final class EpisodeCell: UITableViewCell {
    func configure(_ episode: Episode) {
        textLabel?.numberOfLines = 0
        textLabel?.text = "#\(episode.number) \(episode.title ?? "")"
    }
}
