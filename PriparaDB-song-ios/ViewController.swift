import UIKit
import NorthLayout
import Ikemen
import ReactiveSwift
import ReactiveCocoa
import Differ
import MediaPlayer

final class ViewController: UITableViewController {
    private let viewModel = ViewModel()
    private class ViewModel {
        let lives: Property<[Live]> = Property<EndpointLives>(capturing: DBMaster.sharedLives).map {$0.live}
        private(set) lazy var songs: Property<[Song]> = Property<[Live]>(capturing: lives).map {$0.compactMap {$0.song}}
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        title = "Pripara DB (ライブ)"
    }
    required init?(coder aDecoder: NSCoder) {fatalError()}

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(LiveCell.self, forCellReuseIdentifier: String(describing: LiveCell.self))

        // viewModel.songs.producer
        viewModel.lives.producer
            .combinePrevious([]).startWithValues {[unowned self] a, b in
                self.tableView.animateRowChanges(oldData: a, newData: b)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.lives.value.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LiveCell.self), for: indexPath) as! LiveCell
        let live = viewModel.lives.value[indexPath.row]
        cell.setLive(live)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let song = viewModel.lives.value[indexPath.row].song

        guard let allSongs = MPMediaQuery.songs().items else { return }
        guard let matched = (allSongs.first {$0.title == song.title}) else { return }
        let player = MPMusicPlayerController.iPodMusicPlayer
        player.setQueue(with: .init(items: [matched]))
        player.nowPlayingItem = matched
        player.play()
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
    let coordLabel = UILabel() ※ { // TODO: collections
        $0.textColor = .white
        $0.backgroundColor = #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)
        $0.layer.cornerRadius = 4
        $0.clipsToBounds = true
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let autolayout = northLayoutFormat([:], [
            "song": songLabel,
            "artwork": artworkView,
            "episode": episodeLabel,
            "coord": coordLabel])
        autolayout("H:|[artwork(==64)]-[song]||")
        autolayout("H:[artwork]-[episode]||")
        autolayout("H:[artwork]-[coord]-(>=0)-||")
        autolayout("V:||[song]-[episode]-[coord]||")
        autolayout("V:||[artwork(==64)]-(>=0)-||")
    }
    required init?(coder aDecoder: NSCoder) {fatalError()}

    func setLive(_ live: Live) {
        songLabel.text = "\(live.song.title)\(live.MD.title.map {" — MD " + $0} ?? "")"
        episodeLabel.text = "\(live.episode.series) 第\(live.episode.number)話 \(live.episode.title ?? "")"
        coordLabel.text = live.coordinate.first?.name

        let query = MPMediaQuery.songs()
        query.addFilterPredicate(MPMediaPropertyPredicate(value: live.song.title, forProperty: MPMediaItemPropertyTitle))
        if let matched = query.items?.first {
            artworkView.image = matched.artwork?.image(at: CGSize(width: 64, height: 64))
        } else {
            artworkView.image = nil
        }
    }
}
