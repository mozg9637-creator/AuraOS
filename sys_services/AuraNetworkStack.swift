import EmbeddedSwift

/// Типы сетевых интерфейсов AuraOS
enum NetworkInterfaceType {
    case none
    case wiFi(ssid: Int, strength: Int)
    case cellular(provider: Int, generation: Int)
}

/// Сетевой стек системы (Изменено class на struct для Bare-Metal совместимости)
struct AuraNetworkStack {
    
    // В Bare-Metal для структур синглтон реализуется через статическую переменную
    static var shared = AuraNetworkStack()
    
    var activeInterface: NetworkInterfaceType = .none
    
    init() {
        setupDefaultInterface()
    }
    
    private mutating func setupDefaultInterface() {
        self.activeInterface = .none
    }
    
    mutating func updateInterfaceStatus(to newInterface: NetworkInterfaceType) {
        self.activeInterface = newInterface
    }
}
