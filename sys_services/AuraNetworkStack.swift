import EmbeddedSwift
import AuraGraphics
import AuraHardware // Доступ к сетевым чипам на уровне железа

/// Состояние подключения к интернету
enum NetworkInterfaceType {
    case none
    case wiFi(ssid: String, signalStrength: Int)
    case cellular(provider: String, generation: String) // e.g., "5G", "LTE"
}

class AuraNetworkStack {
    static let shared = AuraNetworkStack()
    
    // Текущий активный интерфейс для пропускания интернет-трафика
    private(set) var activeInterface: NetworkInterfaceType = .none
    
    // Флаги включения модулей в Настройках
    private var isWiFiEnabled: Bool = true
    private var isCellularDataEnabled: Bool = true

    init() {
        print("AuraOS Network: Инициализация сетевого стека...")
    }
    
    /// Запуск мониторинга сетей (вызывается ядром при загрузке)
    func startNetworkMonitor() {
        // Запускаем бесконечный цикл проверки линков на аппаратном уровне
        AuraHardware.Network.registerLinkStateCallback { [weak self] status in
            self?.evaluateRouting(hardwareStatus: status)
        }
    }
    
    /// Стратегия маршрутизации (Приоритет: Wi-Fi всегда на первом месте для экономии батареи и трафика)
    private func evaluateRouting(hardwareStatus: HardwareNetworkStatus) {
        if isWiFiEnabled && hardwareStatus.isWiFiConnected {
            // Если Wi-Fi доступен — пускаем весь трафик через него
            let ssid = AuraHardware.Network.getConnectedSSID()
            let rssi = AuraHardware.Network.getWiFiRSSI()
            activeInterface = .wiFi(ssid: ssid, signalStrength: rssi)
            print("AuraOS Network: Интернет маршрутизируется через Wi-Fi (\(ssid))")
            
        } else if isCellularDataEnabled && hardwareStatus.isCellularRegistered {
            // Если Wi-Fi нет, но включена сотовая сеть — переключаемся на мобильный интернет (Бесшовный Handover)
            let carrier = AuraHardware.Telephony.getCarrierName()
            let tech = AuraHardware.Telephony.getDataTechnology() // "5G" или "LTE"
            activeInterface = .cellular(provider: carrier, generation: tech)
            print("AuraOS Network: Wi-Fi недоступен. Переключение на мобильный интернет \(tech) (\(carrier))")
            
        } else {
            activeInterface = .none
            print("AuraOS Network: Внимание! Устройство отключено от интернета.")
        }
        
        // Перерисовываем системный статус-бар через графический шелл
        AuraShell.shared.triggerStatusBarUpdate()
    }
    
    /// Публичный API для приложений: Отправка HTTP/TCP запроса в сеть
    func sendDataPacket(url: String, method: String, payload: [UInt8], completion: @escaping (Result<[UInt8], NetworkError>) -> Void) {
        switch activeInterface {
        case .none:
            AuraHaptics.vibrate(.error) // Вибрация ошибки подключения
            completion(.failure(.noInternetConnection))
            return
            
        case .wiFi:
            // Формируем пакет для отправки через сетевой чип Wi-Fi
            AuraHardware.Network.transmitViaWiFi(targetUrl: url, httpMethod: method, data: payload) { responseBytes, errCode in
                if errCode == 0 {
                    completion(.success(responseBytes))
                } else {
                    completion(.failure(.hardwareError))
                }
            }
            
        case .cellular:
            // Формируем пакет для отправки через радиомодем (LTE/5G)
            AuraHardware.Telephony.transmitViaModem(targetUrl: url, httpMethod: method, data: payload) { responseBytes, errCode in
                if errCode == 0 {
                    completion(.success(responseBytes))
                } else {
                    completion(.failure(.carrierDrop))
                }
            }
        }
    }
    
    // Включение/Выключение интерфейсов (вызывается из AuraSettingsApp)
    func toggleWiFi(_ enabled: Bool) {
        self.isWiFiEnabled = enabled
        AuraHardware.Network.setWiFiPower(enabled)
        // Принудительно пересчитываем маршруты
        evaluateRouting(hardwareStatus: AuraHardware.Network.getInstantStatus())
    }
    
    func toggleCellularData(_ enabled: Bool) {
        self.isCellularDataEnabled = enabled
        AuraHardware.Telephony.setModemDataPower(enabled)
        evaluateRouting(hardwareStatus: AuraHardware.Network.getInstantStatus())
    }
}

/// Перечисление возможных сетевых ошибок в AuraOS
enum NetworkError: Error {
    case noInternetConnection
    case hardwareError
    case carrierDrop
}
