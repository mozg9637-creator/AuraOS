import AuraUI
import AuraGraphics
import AuraHardware

class AuraPhoneApp: AuraApplication {
    let screenWidth: Float = 1170.0
    let screenHeight: Float = 2532.0
    
    private var isCallActive: Bool = false
    private var dialedNumber: String = "+7 (999) 777-88-99"
    
    override func onRender() {
        if isCallActive {
            // Если звонок идет — рисуем полноэкранный интерфейс вызова (iOS-style)
            renderActiveCallScreen()
        } else {
            // Если звонка нет — классический номеронабиратель
            renderDialerScreen()
        }
    }
    
    private func renderDialerScreen() {
        AuraPainter.drawRect(x: 0, y: 0, width: screenWidth, height: screenHeight, color: .black)
        
        // Показываем текущий набираемый номер
        AuraPainter.drawText(dialedNumber, x: screenWidth / 2 - 160, y: 300, font: .systemRegular(size: 32), color: .white)
        
        // Информация о том, КАКОЙ ТИП СВЯЗИ БУДЕТ ИСПОЛЬЗОВАН (берется из наших Настроек)
        let profile = AuraSystemConfig.shared.activeCallingProfile
        let channelText: String
        switch profile {
        case .cellular: channelText = "Вызов через: Сотовая сеть LTE/GSM"
        case .voWiFi:   channelText = "Вызов через: Wi-Fi Calling (VoWiFi)"
        case .voIP:     channelText = "Вызов через: Интернет-данные (VoIP)"
        }
        AuraPainter.drawText(channelText, x: screenWidth / 2 - 180, y: 380, font: .systemRegular(size: 14), color: .systemBlue)
        
        // Большая зеленая кнопка вызова снизу
        let buttonX = screenWidth / 2
        let buttonY = screenHeight - 400.0
        AuraPainter.drawCircle(x: buttonX, y: buttonY, radius: 75, color: .systemGreen)
        AuraPainter.drawIcon(.phone_pickup, x: buttonX + 22, y: buttonY + 22, tint: .white)
    }
    
    private func renderActiveCallScreen() {
        // Красивый размытый фон вызова
        AuraPainter.drawBlurOverlay(opacity: 0.85, blurRadius: 50.0)
        
        AuraPainter.drawText("ИДЕТ ВЫЗОВ...", x: screenWidth / 2 - 90, y: 200, font: .systemRegular(size: 16), color: .gray)
        AuraPainter.drawText(dialedNumber, x: screenWidth / 2 - 150, y: 280, font: .systemBold(size: 28), color: .white)
        
        // Индикатор канала прямо во время звонка (выводится статус из конфига)
        let currentMode = AuraSystemConfig.shared.activeCallingProfile
        let statusIcon = (currentMode == .voWiFi) ? "HD [Wi-Fi]" : "HD [Cellular]"
        AuraPainter.drawText(statusIcon, x: screenWidth / 2 - 40, y: 340, font: .systemRegular(size: 14), color: .systemGreen)
        
        // Сетка кнопок управления звонком (Громкая связь, Мут микрофона, Клавиатура)
        drawCallControlButtons(y: screenHeight / 2)
        
        // Красная кнопка сброса (End Call)
        let hangUpX = screenWidth / 2
        let hangUpY = screenHeight - 400.0
        AuraPainter.drawCircle(x: hangUpX, y: hangUpY, radius: 75, color: .systemRed)
        AuraPainter.drawIcon(.phone_hangup, x: hangUpX + 22, y: hangUpY + 22, tint: .white)
    }
    
    private func drawCallControlButtons(y: Float) {
        // Рисуем кнопки-круги (заглушка звука, динамик и т.д.)
        AuraPainter.drawGlassCircle(x: screenWidth / 2 - 200, y: y, radius: 45, opacity: 0.2)
        AuraPainter.drawIcon(.mute, x: screenWidth / 2 - 200 + 18, y: y + 18, tint: .white)
        
        AuraPainter.drawGlassCircle(x: screenWidth / 2 + 110, y: y, radius: 45, opacity: 0.2)
        AuraPainter.drawIcon(.speaker, x: screenWidth / 2 + 110 + 18, y: y + 18, tint: .white)
    }
    
    /// Логика запуска звонка
    func makeCall() {
        let activeProfile = AuraSystemConfig.shared.activeCallingProfile
        
        // Архитектурное разветвление: даем ядру команду задействовать нужную подсистему железа
        switch activeProfile {
        case .cellular:
            print("AuraCore Модем: Инициализация GSM-вызова на номер \(dialedNumber)...")
            AuraHardware.Telephony.dialGSM(number: dialedNumber)
            
        case .voWiFi:
            print("AuraCore Wi-Fi: Маршрутизация VoWiFi вызова через текущую точку доступа...")
            AuraHardware.Network.dialVoWiFi(number: dialedNumber)
            
        case .voIP:
            print("AuraCore VoIP: Открытие SIP-сессии передачи аудиопакетов по LTE...")
            AuraHardware.Network.dialVoIP(number: dialedNumber)
        }
        
        isCallActive = true
        AuraHaptics.vibrate(.heavyClick)
    }
    
    func endCall() {
        print("AuraOS Phone: Звонок завершен.")
        AuraHardware.Telephony.hangUpAll()
        isCallActive = false
        AuraHaptics.vibrate(.heavyClick)
    }
    
    func handleTouch(x: Float, y: Float, event: TouchEvent) {
        guard event == .tap else { return }
        
        let targetY = screenHeight - 400.0
        let targetX = screenWidth / 2
        
        let distance = sqrt(pow(x - targetX, 2) + pow(y - targetY, 2))
        if distance <= 75 {
            if isCallActive {
                endCall()
            } else {
                makeCall()
            }
        }
    }
}
