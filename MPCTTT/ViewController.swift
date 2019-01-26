//
//  ViewController.swift
//  MPCTTT
//
//  Created by Kapil Rathore on 29/12/17.
//  Copyright © 2017 Kapil Rathore. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import NotificationCenter

class ViewController: UIViewController {
    
//    @IBOutlet weak var numberLabel: UILabel! {
//        didSet {
//            numberLabel.dropShadow()
//        }
//    }
//
//    @IBOutlet weak var plusButton: MCButton! {
//        didSet {
//            plusButton.tag = 1
//            plusButton.dropShadow()
//            plusButton.layer.cornerRadius = plusButton.frame.height/2
//        }
//    }
//
//    @IBOutlet weak var minusButton: MCButton! {
//        didSet {
//            minusButton.tag = 0
//            minusButton.dropShadow()
//            minusButton.layer.cornerRadius = minusButton.frame.height/2
//        }
//    }
    
    var appDelegate: AppDelegate!
    var currentPlayer = "X"
    var displayNumber: Int = 0 {
        didSet {
//            numberLabel.text = "\(displayNumber)"
        }
    }
    let minLimit = 0
    let maxLimit = 9

    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideKeyboardWhenTappedAround()
        
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        setupConnection()
        displayNumber = 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Adding Observer for keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowNotification(notification:)), name: .UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideNotification(notification:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // removing observers for keyboard
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    // MARK : KeyBoard Observers
    
    @objc func keyboardWillShowNotification(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 64.0 {
                self.view.frame.origin.y -= 258
            }
        }
    }
    
    @objc func keyboardWillHideNotification( notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0 {
                self.view.frame.origin.y += 258
            }
        }
    }
    
    func setupConnection() {
        appDelegate.mpcHandler.setupPeer(with: UIDevice.current.name)
        appDelegate.mpcHandler.setupSession()
        appDelegate.mpcHandler.advertiseSelf(true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(peerDidChangeState(with:)), name: NSNotification.Name(rawValue: "MPC_DidChangeState_Notification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(peerDidReceiveData(with:)), name: NSNotification.Name(rawValue: "MPC_DidReceiveData_Notification"), object: nil)
    }                                     
    
    @IBAction func connectWithPlayer(_ sender: AnyObject) {
        if appDelegate.mpcHandler.session != nil {
            appDelegate.mpcHandler.setupBrowser()
            appDelegate.mpcHandler.browser.delegate = self
            present(appDelegate.mpcHandler.browser, animated: true, completion: nil)
        }
    }
    
    @IBAction func sendMessage(_ sender: UIButton) {

        let messageDict = [
            "type" : "text",
            "message" : "kapil"
        ]
        guard let messageData = try? JSONSerialization.data(withJSONObject: messageDict, options: .prettyPrinted) else { return }
        try? appDelegate.mpcHandler.session.send(messageData, toPeers: appDelegate.mpcHandler.session.connectedPeers, with: .reliable)

        performAction(sender.tag)
    }
    
    @objc func peerDidChangeState(with notification: Notification) {
        
        let userInfo = NSDictionary(dictionary: notification.userInfo!)
        let state = userInfo.object(forKey: "state") as! Int
        
        switch state {
        case MCSessionState.notConnected.rawValue:
            navigationItem.title = "Sleep"
        case MCSessionState.connecting.rawValue:
            navigationItem.title = "Connecting"
        case MCSessionState.connected.rawValue:
            navigationItem.title = "Connected"
            appDelegate.mpcHandler.advertiseSelf(false)
        default:
            navigationItem.title = "None"
        }
    }
    
    @objc func peerDidReceiveData(with notification: Notification) {
        let userInfo = notification.userInfo! as Dictionary
        let data  = userInfo["data"] as! Data
        
        if let message = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSDictionary {
            let action = message["action"] as! Int
            performAction(action)
        }
    }
    
    func performAction(_ action: Int) {
        if action == 0 {
            displayNumber -= 1
        } else if action == 1 {
            displayNumber += 1
        }
    }
}

extension ViewController: MCBrowserViewControllerDelegate {
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        appDelegate.mpcHandler.browser.dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        appDelegate.mpcHandler.browser.dismiss(animated: true, completion: nil)
    }
}
