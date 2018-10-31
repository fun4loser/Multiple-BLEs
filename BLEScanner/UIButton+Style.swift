
import UIKit

extension UIButton {
    func style(with color: UIColor) {
        layer.borderWidth = 1.5
        layer.borderColor = color.cgColor
        layer.cornerRadius = 3
    }
    
    func setupDisabledState() {
        setTitleColor(.lightGray, for: .disabled)
    }
    
    func update(isScanning: Bool){
        let title = isScanning ? "Stop Scanning" : "Start Scanning"
        setTitle(title, for: UIControlState())
        
        let titleColor: UIColor = isScanning ? .btBlue : .white
        setTitleColor(titleColor, for: UIControlState())
        
        backgroundColor = isScanning ? UIColor.clear : .btBlue
    }
}
