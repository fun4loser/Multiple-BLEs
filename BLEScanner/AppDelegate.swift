

import UIKit
import Foundation
import CoreBluetooth

extension Notification.Name {
    public static let myNotificationKey = Notification.Name(rawValue: "myNotificationKey")
    
    public static let bleNotif = Notification.Name(rawValue: "bleNotif")
    
    public static let startScanNotif = Notification.Name(rawValue: "startScanNotif")
    
    public static let scanStateNotif = Notification.Name(rawValue: "scanStateNotif")
    
    public static let connectPeripheral = Notification.Name(rawValue: "connectPeripheral")
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CBPeripheralDelegate {
    
    var window: UIWindow?
    
    var ble: bleScanner?
    
    var peripherals = Set<NSDictionary>()
    
    var bleON = false
    var bleScanning = false
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        ble = bleScanner()
        return true
    }
    
    
    func setPeripherals(array: Set<NSDictionary>){
        peripherals = array
    }
    
}


