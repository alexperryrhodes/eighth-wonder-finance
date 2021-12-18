//
//  ProfileViewController.swift
//  Eighth Wonder Finance
//
//  Created by Joshua Harris on 10/27/21.
//

import UIKit
import Parse
import AlamofireImage

class ProfileViewController: UIViewController {

    
    @IBOutlet weak var darkmodeSegControl: UISegmentedControl!
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    var user: PFObject? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkDarkMode()
        usernameLabel.text = PFUser.current()?.username
        // Do any additional setup after loading the view.
        
        self.title = "Settings"
        
        let user = PFUser.current()
        if user != nil {
            do {
                let query = try PFQuery.getUserObject(withId: user!.objectId!)
                self.user = query
            } catch {
                print(error)
            }
        }
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    
  
    @IBAction func onDarkModeSegControl(_ sender: Any) {
        // toggle dark mode segmented control
        let userDefaults = UserDefaults.standard
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let delegate = windowScene.delegate as? SceneDelegate else { return }
        
        switch darkmodeSegControl.selectedSegmentIndex
        {
        case 0:
            print("Light")
            delegate.window?.overrideUserInterfaceStyle = .light
            userDefaults.set(false, forKey: "darkMode")
        case 1:
            print("Dark")
            delegate.window?.overrideUserInterfaceStyle = .dark
            userDefaults.set(true, forKey: "darkMode")
        default:
            checkDarkMode()
        }
        checkDarkMode()
    }
    
    
    @IBAction func onLogoutButton(_ sender: Any) {
        // logout
        print("Logout pressed")
        
        let refreshAlert = UIAlertController(title: "Log Out?", message: "Are you sure you want to log out?", preferredStyle: UIAlertController.Style.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Yes", style: .default,
                                             handler: {(action: UIAlertAction!) in
            print("User pressed yes")
            // log out
            PFUser.logOut()
            
            let main = UIStoryboard(name: "Main", bundle: nil)
            let loginViewController = main.instantiateViewController(withIdentifier: "LoginViewController")
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let delegate = windowScene.delegate as? SceneDelegate else { return }
            
            delegate.window?.rootViewController = loginViewController
            
        }))
        refreshAlert.addAction(UIAlertAction(title: "No", style: .cancel,
                                             handler: {(action: UIAlertAction!) in
            print("User pressed no")
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
    
    @IBAction func onResetButton(_ sender: Any) {
        // reset cash to deafault value, and remove all transcations/holdings
        print("Reset button clicked")
        let refreshAlert = UIAlertController(title: "Restart Game?",
                                             message: "Are you sure you want to restart the game?",preferredStyle: UIAlertController.Style.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Yes", style: .default,
                                             handler: {(action: UIAlertAction!) in
            print("User pressed yes")
            // reset balance to 50,000
            self.user!["balance"] = 50000
            self.user?.saveInBackground()
            
            // delete Stocks
            let query = PFQuery(className: "Stock")
            query.whereKey("user", equalTo: self.user)
            query.findObjectsInBackground {(objects: [PFObject]?, error: Error?) in
                if let error = error {
                    // Log details of the failure
                    print(error.localizedDescription)
                } else if let objects = objects {
                    // The find succeeded.
                    print("Successfully retrieved \(objects.count) stocks.")
                    if objects.count == 0 {
                        print("Nothing to delete")
                    }
                    if objects.count > 0 {
                        for object in objects {
                            print(object)
                            object.deleteInBackground()
                        }
                    }
                }
            }
        }))
        refreshAlert.addAction(UIAlertAction(title: "No", style: .cancel,
                                             handler: {(action: UIAlertAction!) in
            print("User pressed no")
        }))
        
        present(refreshAlert, animated: true, completion: nil)
        
    }

    func checkDarkMode() {
        // add this code along with window code above to home view (initial view will set all views to dark/light)
        let userDefaults = UserDefaults.standard
        if userDefaults.bool(forKey: "darkMode") == true {
            overrideUserInterfaceStyle = .dark
            darkmodeSegControl.selectedSegmentIndex = 1
        } else {
            overrideUserInterfaceStyle = .light
            darkmodeSegControl.selectedSegmentIndex = 0
        }
    }
    
}
