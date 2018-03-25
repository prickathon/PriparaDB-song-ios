import UIKit
import NorthLayout
import Ikemen
import ReactiveSwift
import ReactiveCocoa

final class ViewController: UIViewController {
    private let viewModel = ViewModel()
    private class ViewModel {
        let lives: MutableProperty<[Live]>

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
}
