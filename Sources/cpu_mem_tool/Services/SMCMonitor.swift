import Foundation
import IOKit

/// SMC (System Management Controller) 温度读取器
/// 通过 IOKit 连接 AppleSMC 服务获取传感器数据
enum SMCMonitor {
    /// SMC 数据结构 —— 值
    private struct SMCVal {
        var key: (CChar, CChar, CChar, CChar, CChar) = (0, 0, 0, 0, 0)
        var dataSize: UInt32 = 32
        var dataType: (CChar, CChar, CChar, CChar, CChar) = (0, 0, 0, 0, 0)
        var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0)
    }

    /// SMC 选择器常量
    private static let kSMCUserClientOpen  = UInt32(0)
    private static let kSMCUserClientClose = UInt32(1)
    private static let kSMCHandleYPCEvent  = UInt32(2)
    private static let kSMCReadKey         = UInt32(5)
    private static let kSMCGetKeyInfo      = UInt32(9)

    /// 读取 SMC key 返回 Double 值（温度等）
    static func readDouble(_ key: String) -> Double? {
        guard let conn = openConnection() else { return nil }
        defer { closeConnection(conn) }

        var val = SMCVal()
        guard readSMC(conn, key, &val) else { return nil }

        // 解析数据类型
        let type = dataTypeString(val.dataType)

        switch type {
        case "flt ", "flta":
            return parseFloat(val.bytes)
        case "sp78", "sp87":
            // 温度常用的 Apple 浮点格式: 有符号 16 位整数 / 256
            let intVal = Int16(bitPattern: UInt16(val.bytes.0) << 8 | UInt16(val.bytes.1))
            return Double(intVal) / 256.0
        default:
            return nil
        }
    }

    // MARK: - SMC 连接管理

    private static func openConnection() -> io_connect_t? {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("AppleSMC")
        )
        guard service != 0 else { return nil }

        var conn: io_connect_t = 0
        let result = IOServiceOpen(service, mach_task_self_, 0, &conn)
        IOObjectRelease(service)

        guard result == KERN_SUCCESS else { return nil }
        return conn
    }

    private static func closeConnection(_ conn: io_connect_t) {
        IOServiceClose(conn)
    }

    // MARK: - SMC 读写

    private static func readSMC(_ conn: io_connect_t, _ key: String, _ val: inout SMCVal) -> Bool {
        // 先获取 key 信息
        var keyInfo = SMCVal()
        guard getKeyInfo(conn, key, &keyInfo) else { return false }

        val.key = keyInfo.key
        val.dataSize = keyInfo.dataSize
        val.dataType = keyInfo.dataType

        // 再读取值
        var inputStruct = keyInfoWithSelector(kSMCReadKey)
        inputStruct.key = keyInfo.key

        let inputSize = MemoryLayout<SMCVal>.size
        var outputSize = MemoryLayout<SMCVal>.size

        let result = IOConnectCallStructMethod(
            conn,
            kSMCHandleYPCEvent,
            &inputStruct,
            inputSize,
            &val,
            &outputSize
        )

        return result == KERN_SUCCESS
    }

    private static func getKeyInfo(_ conn: io_connect_t, _ key: String, _ info: inout SMCVal) -> Bool {
        var inputStruct = keyInfoWithSelector(kSMCGetKeyInfo)
        withUnsafeMutablePointer(to: &inputStruct.key) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: 5) { cptr in
                let bytes = key.utf8CString
                for i in 0..<min(bytes.count, 4) {
                    cptr[i] = bytes[i]
                }
            }
        }

        let inputSize = MemoryLayout<SMCVal>.size
        var outputSize = MemoryLayout<SMCVal>.size

        let result = IOConnectCallStructMethod(
            conn,
            kSMCHandleYPCEvent,
            &inputStruct,
            inputSize,
            &info,
            &outputSize
        )

        return result == KERN_SUCCESS
    }

    private static func keyInfoWithSelector(_ selector: UInt32) -> SMCVal {
        var val = SMCVal()
        // 将 selector 写入 dataSize 的前 4 字节
        withUnsafeMutableBytes(of: &val.dataSize) { ptr in
            ptr.storeBytes(of: selector, as: UInt32.self)
        }
        return val
    }

    // MARK: - 数据解析

    private static func dataTypeString(_ dataType: (CChar, CChar, CChar, CChar, CChar)) -> String {
        var chars = [dataType.0, dataType.1, dataType.2, dataType.3]
        return String(cString: &chars)
    }

    private static func parseFloat(_ bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                                            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                                            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                                            UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)) -> Double? {
        var val: Float = 0
        withUnsafeMutableBytes(of: &val) { ptr in
            ptr[0] = bytes.0
            ptr[1] = bytes.1
            ptr[2] = bytes.2
            ptr[3] = bytes.3
        }
        return val.isNaN ? nil : Double(val)
    }
}
