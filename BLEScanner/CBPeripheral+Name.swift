
import Foundation
import CoreBluetooth

extension CBPeripheral {
    var displayName: String {
        guard let name = name, !name.isEmpty else { return "No Device Name" }
        return name
    }
}
