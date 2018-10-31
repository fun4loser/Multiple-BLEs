

import CoreBluetooth
import UIKit

struct DisplayPeripheral: Hashable {
    //Makes it possible to store our type in a set
    var hashValue: Int { return peripheral.hashValue }
    
    let peripheral: CBPeripheral
    //Relative received signal strength
    let lastRSSI: NSNumber
    let isConnectable: Bool

    static func ==(lhs: DisplayPeripheral, rhs: DisplayPeripheral) -> Bool {
        return lhs.peripheral == rhs.peripheral
    }
}

class bleGUI: UIViewController {
    
    let screenSize = UIScreen.main.bounds
    
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet private weak var scanningButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    
    //Pop up displayed when actively connecting to a device
    var connectingViewController: UIViewController?
    
    private var centralManager: CBCentralManager!
    
    //Sets to store various types of peripherals
    private var displayPeripherals = Set<DisplayPeripheral>()
    private var allPeripherals = Set<CBPeripheral>()
    private var connectedPeripherals = Set<DisplayPeripheral>()
    
    private var guiRefreshTimer: Timer?
    
    private var selectedPeripheral: CBPeripheral?
    
    @IBOutlet weak var infoLabel: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    
    //Stores values of to connected peripherals, one of each hand
    var peripheralValArray : [[Float]] = [[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]]
    

    var connectedAmount = 0

    //Which hand is selected from the list
    var hand = 0
    
    
    var guiButtons = [UIView]()
    var strumIndicator = UIView()
    var strumBG = UIView()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateStatusText("")
        scanningButton.setupDisabledState()
        scanningButton.style(with: .btBlue)
        
        if(delegate.bleScanning){
            scanningButton.update(isScanning: true)
        }else{

        }
        
        scanningButton.isEnabled = delegate.bleON
        
        setupNavBar()
        tableView.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 74
        
        //Setup notifications that trigger from the scanners back end
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshScanView(_:)), name: Notification.Name.myNotificationKey, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.bluetoothStateChanged(_:)), name: Notification.Name.bleNotif, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.scanStateChanged(_:)), name: Notification.Name.scanStateNotif, object: nil)
        
        
        guiButtons.reserveCapacity(8)
        for i in stride(from: 0, to: 8, by: 1) {
            guiButtons.append(UIView())
        }
        
        
        //Device  button indicator setup
        for i in stride(from: 0, to: 8, by: 1){
            let btnBG:UIView
            if i < 4{
                btnBG = UIView(frame: CGRect(x: Int(screenSize.width*0.0175) + Int(screenSize.width * 0.245) * i, y: Int(screenSize.height * 0.7), width: Int(screenSize.width * 0.24), height: Int(screenSize.height * 0.027)))
                btnBG.backgroundColor = UIColor(red: 255/255.0, green: 50/255.0, blue: 100/255.0, alpha: 1.0)
            }else{
                btnBG = UIView(frame: CGRect(x: Int(screenSize.width*0.0175) + Int(screenSize.width * 0.245) * (i - 4), y: Int(screenSize.height * 0.7) + Int(screenSize.height * 0.029), width: Int(screenSize.width * 0.24), height: Int(screenSize.height * 0.027)))
                btnBG.backgroundColor = UIColor(red: 100/255.0, green: 50/255.0, blue: 255/255.0, alpha: 1.0)
            }
            self.view.addSubview(btnBG)
            
            
            var frame:CGRect
            if i < 4{
                frame = CGRect(x: Int(screenSize.width*0.0175) + Int(screenSize.width * 0.245) * i, y: Int(screenSize.height * 0.7), width: Int(screenSize.width * 0.24), height: Int(screenSize.height * 0.027))
            }else{
                frame = CGRect(x: Int(screenSize.width*0.0175) + Int(screenSize.width * 0.245) * (i - 4), y: Int(screenSize.height * 0.7) + Int(screenSize.height * 0.029), width: Int(screenSize.width * 0.24), height: Int(screenSize.height * 0.027))
            }
            guiButtons[i] = UIView(frame: frame)
            guiButtons[i].backgroundColor = UIColor(red: 255/255.0, green: 255/255.0, blue: 255/255.0, alpha: 0.0)
            self.view.addSubview(guiButtons[i])
        }
        
        //Strum GUI Background
        strumBG = UIView(frame: CGRect(x: Int(screenSize.width*0.0175), y: Int(screenSize.height * 0.757), width: Int(screenSize.width * 0.968), height: Int(screenSize.height * 0.027)))
        strumBG.backgroundColor = UIColor(red: 255/255.0, green: 255/255.0, blue: 255/255.0, alpha: 1.0)
        self.view.addSubview(strumBG)
        
        
        //Strum GUI Indicator
        strumIndicator = UIView(frame: CGRect(x: 0, y: 0, width: Int(screenSize.width * 0.1), height: Int(screenSize.height * 0.025)))
        strumIndicator.center = CGPoint(x: strumBG.center.x, y: strumBG.center.y)
        strumIndicator.backgroundColor = .lightGray
        self.view.addSubview(strumIndicator)
        
        guiRefreshTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(refreshGUI), userInfo: nil, repeats: true)
        
        
        //Add peripharls already found in the background BLE Scanner
        
        let periArray = Array(delegate.peripherals)
        
        for (index, peripheralDict) in periArray.enumerated() {

            let receivedPeripheral = peripheralDict["peripheral"] as! CBPeripheral
            let receivedRSSI = peripheralDict["rssi"] as! NSNumber
            
            let displayPeripheral = DisplayPeripheral(peripheral: receivedPeripheral, lastRSSI: receivedRSSI, isConnectable: true)
            
            var periTempName = ""
            periTempName = periTempName + (receivedPeripheral.name ?? "")
            periTempName = String(periTempName.prefix(4))
            
            if(periTempName == "Kurv"){
                displayPeripherals.insert(displayPeripheral)
            }
        }
        
        tableView.reloadData()
        
    }
    
    
    @objc func refreshGUI(){
        var frame:CGRect
        
        for i in stride(from: 0, to: 8, by: 1){
            guiButtons[i].backgroundColor = UIColor(red: 255/255.0, green: 255/255.0, blue: 255/255.0, alpha: CGFloat(peripheralValArray[hand][(9+i)]))
        }
        
        var strumPos = CGFloat(strumBG.center.x) + CGFloat(peripheralValArray[hand][4] * -120)
        
        //Strum Meter indicator movement
        strumIndicator.center = CGPoint(x: strumPos, y: strumBG.center.y)
    }
    
    //Count peripherals currently connected
    @objc func countConnected(){
        let serviceUUID = CBUUID(string: "180A")
        connectedAmount = self.centralManager.retrieveConnectedPeripherals(withServices:[serviceUUID]).count
        
        let plural = displayPeripherals.count > 1 ? "s" : ""
        updateStatusText("\(displayPeripherals.count) Device\(plural) Found, \(connectedAmount) Connected.")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        selectedPeripheral = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    //Setup navigation bar
    private func setupNavBar() {
        navigationController?.navigationBar.barTintColor = .btBlue
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        let backButton = UIBarButtonItem(title: "Disconnect", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
        backButton.tintColor = .white
        navigationItem.backBarButtonItem = backButton
    }

    
    @objc func scanStateChanged(_ notification: Notification){
        
        let scanState = notification.object as! Bool
        
        if(scanState){
            updateViewForStartScanning()
        }else{
            updateViewForStopScanning()
        }
    }
    
    private func updateViewForStartScanning(){
        updateStatusText("Scanning BLE Devices...")
        scanningButton.update(isScanning: true)
    }
    
    private func updateViewForStopScanning(){
        let plural = displayPeripherals.count > 1 ? "s" : ""
        updateStatusText("\(displayPeripherals.count) Device\(plural) Found, \(connectedAmount) Connected.")
        scanningButton.update(isScanning: false)
        
    }
    
    
    @IBAction private func scanningButtonPressed(_ sender: AnyObject){
        if(delegate.bleScanning){
            updateViewForStopScanning()
            NotificationCenter.default.post(name: .startScanNotif, object: false)
        }else{
            updateViewForStartScanning()
            displayPeripherals = []
            tableView.reloadData()
            NotificationCenter.default.post(name: .startScanNotif, object: true)
        }
    }
    
    //Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let connectingVC = segue.destination as? ConnectingViewController {
            connectingVC.delegate = self
            if let selectedPeripheral = selectedPeripheral {
                connectingVC.peripheralName = selectedPeripheral.displayName
            }
            
            connectingViewController = connectingVC
        }
    }
    
    private func showLoading() {
        performSegue(withIdentifier: "LoadingSegue", sender: self)
    }
    
    private func updateStatusText(_ text: String) {
        title = text
    }
    
    
    @objc func refreshScanView(_ notification: Notification) {
        let dict = notification.object as! NSDictionary
        let receivedPeripheral = dict["peripheral"] as! CBPeripheral
        let receivedRSSI = dict["rssi"] as! NSNumber
        
        let displayPeripheral = DisplayPeripheral(peripheral: receivedPeripheral, lastRSSI: receivedRSSI, isConnectable: true)
        displayPeripherals.insert(displayPeripheral)
        tableView.reloadData()
    }
    
    @objc func bluetoothStateChanged(_ notification: Notification) {
        scanningButton.isEnabled = delegate.bleON
    }
    
}


//Get device hand direction
func getDeviceDirection(_ name :String) -> String{
    
    let name = String(name.prefix(10))
    
    if(name == "Controller Left "){
        return "LEFT"
    }else if(name == "Controller Right"){
        return "RIGHT"
    }else{
        return ""
    }
    
}


extension bleGUI: UITableViewDataSource {
    
    //Cell for row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        if displayPeripherals.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "emptyCell")!
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! DeviceTableViewCell
        
        let peripheralsArray = Array(displayPeripherals)
        if peripheralsArray.count > indexPath.row {
            cell.populate(displayPeripheral: peripheralsArray[indexPath.row])
        }
        
        cell.tag = indexPath.row
        cell.delegate = self
        return cell
    }
    
    //Number of rows in section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (displayPeripherals.count + connectedPeripherals.count) > 0 {
            return (displayPeripherals.count + connectedPeripherals.count)
        } else {
            return 1
        }
    }
    
    
    //Did select row
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let peripheralsArray = Array(displayPeripherals)
        
        nameLabel.text = peripheralsArray[indexPath.row].peripheral.name
        nameLabel.text = "Found " + nameLabel.text!
        
        if(getDeviceDirection(peripheralsArray[indexPath.row].peripheral.name!) == "LEFT"){
            hand = 0
        }else if(getDeviceDirection(peripheralsArray[indexPath.row].peripheral.name!) == "RIGHT"){
            hand = 1
        }
    }
    
    //Did discover services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
        }
        
        peripheral.services?.forEach({ (service) in
            tableView.reloadData()
            peripheral.discoverCharacteristics(nil, for: service)
        })
    }
}

//Height for row
extension bleGUI: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return displayPeripherals.count > 0 ? UITableViewAutomaticDimension : tableView.frame.size.height
    }
}

//Handle tapping connecto on device cell
extension bleGUI: DeviceCellDelegate {
    func didTapConnect(_ cell: DeviceTableViewCell, peripheral: CBPeripheral) {
        selectedPeripheral = peripheral

        if peripheral.state != .connected {

            NotificationCenter.default.post(name: .connectPeripheral, object: peripheral)
            showLoading()

        }
    }
}

//Dismiss connection view
extension bleGUI: ConnectingViewControllerDelegate {
    func didTapCancel(_ vc: ConnectingViewController) {
        connectingViewController?.dismiss(animated: true)
    }
}



