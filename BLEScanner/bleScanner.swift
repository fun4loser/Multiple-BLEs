
import CoreBluetooth
import Foundation
import UIKit

class bleScanner : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private var centralManager: CBCentralManager!
    private var peripheralsDict = Set<NSDictionary>()
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    //Timer that checks central managers state
    private var checkStateTimer: Timer?
    
    override init() {
        super.init()
        //Setup central manager
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        //Notify scanner to change state when altered by GUI
        NotificationCenter.default.addObserver(self, selector: #selector(self.changeScanState), name: Notification.Name.startScanNotif, object: nil)
        //Notify scanner to connect to peripheral when prompted by GUI
        NotificationCenter.default.addObserver(self, selector: #selector(self.connectPeripheral), name: Notification.Name.connectPeripheral, object: nil)
    }
    

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            print("CoreBluetooth BLE hardware is powered off");
            delegate.bleON = false
            break;
        case .poweredOn:
            print("CoreBluetooth BLE hardware is powered on and ready");
            delegate.bleON = true
            startScanning()
            break;
        case .resetting:
            print("CoreBluetooth BLE hardware is resetting");
            delegate.bleON = false
            break;
        case .unauthorized:
            print("CoreBluetooth BLE state is unauthorized");
            delegate.bleON = false
            break;
        case .unknown:
            print("CoreBluetooth BLE state is unknown");
            delegate.bleON = false
            break;
        case .unsupported:
            print("CoreBluetooth BLE hardware is unsupported on this platform");
            delegate.bleON = false
            break;
        default:
            break;
        }
        //Notify GUI about central manager state
        NotificationCenter.default.post(name: .bleNotif, object: nil)
    }
    
    @objc func changeScanState(_ notification: Notification){
        let scanState = notification.object as! Bool
        if(scanState){
            startScanning()
        }else{
            centralManager?.stopScan()
        }
    }
    
    @objc func startScanning() {
        print("Started scaning")
        self.centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.centralManager!.isScanning {
                strongSelf.centralManager?.stopScan()
                
            }
        }
        checkStateTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(checkState), userInfo: nil, repeats: true)
        
    }
    
    //Check if central manager is scanning
    @objc func checkState(){
        if centralManager.isScanning{
            delegate.bleScanning = true
            NotificationCenter.default.post(name: .scanStateNotif, object: delegate.bleScanning)
        }else{
            print("Stopped scanning")
            delegate.bleScanning = false
            NotificationCenter.default.post(name: .scanStateNotif, object: delegate.bleScanning)
            checkStateTimer?.invalidate()
        }
        
    }
    

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber){
        
        print("Did discover device: \(String(describing: peripheral.name))")
        
        //Will only display devices with a name that start the following way
        var desiredDeviceName = "Dev"
        
        //Get prefix of device
        var deviceTempName = "" + (peripheral.name ?? "")
        deviceTempName = String(deviceTempName.prefix(desiredDeviceName.count))
        
        if(deviceTempName == desiredDeviceName){
            let peripheralDict = [ "peripheral": peripheral, "rssi": RSSI] as [String : Any]
            peripheralsDict.insert([ "peripheral": peripheral, "rssi": RSSI])
            NotificationCenter.default.post(name: .myNotificationKey, object: peripheralDict)
            delegate.setPeripherals(array: peripheralsDict)
        }
        
    }
    
    
    @objc func connectPeripheral(_ notification: Notification){
        let peripheral = notification.object as! CBPeripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Did connect peripheral")
        peripheral.discoverServices(nil)
        peripheral.delegate = self
    }
    
    
}
