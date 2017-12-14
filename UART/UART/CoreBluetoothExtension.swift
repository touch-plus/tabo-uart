
import CoreBluetooth

public extension CBManagerState
{
    var name:NSString {
        get {
            let enumName = "CBManagerState"
            var valueName = ""
            
            switch self {
            case .poweredOff:
                valueName = enumName + ".poweredOff"
            case .poweredOn:
                valueName = enumName + ".poweredOn"
            case .resetting:
                valueName = enumName + ".resetting"
            case .unauthorized:
                valueName = enumName + ".unauthorized"
            case .unknown:
                valueName = enumName + ".unknown"
            case .unsupported:
                valueName = enumName + ".unsupported"
            }
            
            return valueName as NSString
        }
    }
}

public extension CBPeripheralState
{
    var name:NSString {
        get {
            let enumName = "CBPeripheralState"
            var valueName = ""
            
            switch self {
            case .connected:
                valueName = enumName + ".connected"
            case .connecting:
                valueName = enumName + ".connecting"
            case .disconnected:
                valueName = enumName + ".disconnected"
            default :
                break
            }
            
            return valueName as NSString
        }
    }
}

