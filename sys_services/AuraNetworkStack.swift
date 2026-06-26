import EmbeddedSwift

/// Типы сетевых интерфейсов AuraOS (Добавлено глобально для исправления ошибки компиляции)
enum NetworkInterfaceType {
    case none
    case wiFi(ssid: Any, strength: Int)
    case cellular(provider: Any, generation: String)
}

class AuraNetworkStack {
    static let shared = AuraNetworkStack()
    
    // Теперь этот тип гарантированно находится в scope
    var activeInterface: NetworkInterfaceType = .none
    
    private init() {
        // Базовая инициализация драйвера сетевой карты
        setupDefaultInterface()
    }
    
    private func setupDefaultInterface() {
        self.activeInterface = .none
    }
    
    func updateInterfaceStatus(to newInterface: NetworkInterfaceType) {
        self.activeInterface = newInterface
    }
}
