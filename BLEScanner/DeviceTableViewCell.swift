

import UIKit
import CoreBluetooth

protocol DeviceCellDelegate: class {
    func didTapConnect(_ cell: DeviceTableViewCell, peripheral: CBPeripheral)
}

class DeviceTableViewCell: UITableViewCell {
	@IBOutlet weak private var deviceNameLabel: UILabel!
	@IBOutlet weak private var deviceRssiLabel: UILabel!
	@IBOutlet weak private var connectButton: UIButton!
	
	weak var delegate: DeviceCellDelegate?
	private var displayPeripheral: DisplayPeripheral!
    
    func populate(displayPeripheral: DisplayPeripheral) {
        self.displayPeripheral = displayPeripheral
        deviceNameLabel.text = displayPeripheral.peripheral.displayName
        
        deviceRssiLabel.text = "\(displayPeripheral.lastRSSI)dB"
        connectButton.isHidden = !displayPeripheral.isConnectable
    }
	
	@IBAction private func connectButtonPressed(_ sender: AnyObject) {
		delegate?.didTapConnect(self, peripheral: displayPeripheral.peripheral)
        if(!connectButton.isSelected){
            connectButton.setTitle("Disconnect",for: .normal)
        }else{
           connectButton.setTitle("Connect",for: .normal)
        }
        connectButton.isSelected = !connectButton.isSelected;
	}
}
