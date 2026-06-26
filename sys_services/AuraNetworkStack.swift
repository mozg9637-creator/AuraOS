import EmbeddedSwift

/// Типы сетевых интерфейсов AuraOS
enum NetworkInterfaceType {
    case none
    case wiFi(ssid: Int, strength: Int)
    case cellular(provider: Int, generation: Int)
}

// Глобальный экземпляр для линкера, чтобы избежать скрытых вызовов thread-safe инициализации
private let _globalSharedNetworkStack = AuraNetworkStack()

class AuraNetworkStack {
    // Безопасный для Embedded Swift синглтон без вызова скрытых библиотечных геттеров
    static var shared: AuraNetworkStack {
        return _globalSharedNetworkStack
    }
    
    var activeInterface: NetworkInterfaceType = .none
    
    fileprivate init() {
        setupDefaultInterface()
    }
    
    private func setupDefaultInterface() {
        self.activeInterface = .none
    }
    
    func updateInterfaceStatus(to newInterface: NetworkInterfaceType) {
        self.activeInterface = newInterface
    }
}
