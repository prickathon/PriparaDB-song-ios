import UIKit
import NorthLayout
import Ikemen
import ReactiveSwift
import ReactiveCocoa
import Differ
import MediaPlayer
import TagListView

func librarySongByTitle(_ title: String) -> MPMediaItem? {
    let query = MPMediaQuery.songs()
    query.addFilterPredicate(MPMediaPropertyPredicate(value: title, forProperty: MPMediaItemPropertyTitle))
    return query.items?.first
}

final class ViewController: UITableViewController {
    private let viewModel = ViewModel()
    private class ViewModel {
        let lives: Property<[Live]> = Property<EndpointLives>(capturing: DBMaster.sharedLives).map {$0.lives}
        private(set) lazy var songs: Property<[Song]> = Property<[Live]>(capturing: lives).map {$0.compactMap {$0.song}}

        let filter = MutableProperty<String?>(nil)
        private(set) lazy var filteredLives: Property<[Live]> = Property.combineLatest(lives, filter).map { lives, filter -> [Live] in
            guard let filter = filter, !filter.isEmpty else { return lives }
            return lives.filter {
                $0.song.title.range(of: filter, options: [.caseInsensitive, .widthInsensitive]) != nil ||
                    $0.MD.title?.range(of: filter, options: [.caseInsensitive, .widthInsensitive]) != nil ||
                    $0.coordinate.contains {$0.name.range(of: filter, options: [.caseInsensitive, .widthInsensitive]) != nil}
            }
        }
    }

    let searchController = UISearchController(searchResultsController: nil)

    init() {
        super.init(nibName: nil, bundle: nil)
        title = "Pripara DB (ライブ)"
    }
    required init?(coder aDecoder: NSCoder) {fatalError()}

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        }
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false

        tableView.register(LiveCell.self, forCellReuseIdentifier: String(describing: LiveCell.self))

        // viewModel.songs.producer
        viewModel.filteredLives.producer
            .combinePrevious([]).startWithValues {[unowned self] a, b in
                self.tableView.animateRowChanges(oldData: a, newData: b)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.filteredLives.value.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LiveCell.self), for: indexPath) as! LiveCell
        let live = viewModel.filteredLives.value[indexPath.row]
        cell.setLive(live)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let song = viewModel.filteredLives.value[indexPath.row].song
        if let mediaItem = librarySongByTitle(song.title) {
            let ac = UIAlertController(title: "\(song.title)を再生", message: mediaItem.artist, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
            ac.addAction(UIAlertAction(title: "再生", style: .default, handler: {_ in
                let player = MPMusicPlayerController.iPodMusicPlayer
                player.setQueue(with: .init(items: [mediaItem]))
                player.nowPlayingItem = mediaItem
                player.play()
            }))
            present(ac, animated: true)
        }
    }
}

extension ViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.filter.value = searchController.searchBar.text
    }
}

final class LiveCell: UITableViewCell {
    let songLabel = UILabel() ※ {
        $0.textColor = .black
        $0.numberOfLines = 0
    }
    let artworkView = UIImageView() ※ {
        $0.contentMode = .scaleAspectFill
    }
    let episodeLabel = UILabel() ※ {
        $0.textColor = .lightGray
        $0.numberOfLines = 0
    }
    let coordsView = TagListView(frame: .zero) ※ {
        $0.cornerRadius = 4
        $0.textFont = .systemFont(ofSize: 14)
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let autolayout = northLayoutFormat([:], [
            "song": songLabel,
            "artwork": artworkView,
            "episode": episodeLabel,
            "coord": coordsView])
        autolayout("H:||[artwork(==64)]-[song]||")
        autolayout("H:[artwork]-[episode]||")
        autolayout("H:||[coord]||")
        autolayout("V:||[song]-[episode]-(>=8)-[coord]||")
        autolayout("V:||[artwork(==64)]-(>=8)-[coord]||")
    }
    required init?(coder aDecoder: NSCoder) {fatalError()}

    func setLive(_ live: Live) {
        songLabel.text = "\(live.song.title)\(live.MD.title.map {" — MD " + $0} ?? "")"
        artworkView.image = librarySongByTitle(live.song.title)?.artwork?.image(at: CGSize(width: 64, height: 64))
        episodeLabel.text = "\(live.episode.series) 第\(live.episode.number)話 \(live.episode.title ?? "")"
        coordsView.removeAllTags()
        coordsView.addTags(live.coordinate.map {$0.name}).forEach {
            $0.tagBackgroundColor = #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)
        }
    }
}
