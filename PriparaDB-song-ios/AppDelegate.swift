import UIKit
import Ikemen
import SVProgressHUD
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()

        SVProgressHUD.setDefaultMaskType(.black)

        let window = UIWindow()
        window.rootViewController = UITabBarController() ※ {
            $0.viewControllers = [
                UINavigationController(rootViewController: ViewController()),
                UINavigationController(rootViewController: SettingsViewController())]
        }
        window.makeKeyAndVisible()
        self.window = window

        return true
    }
}

