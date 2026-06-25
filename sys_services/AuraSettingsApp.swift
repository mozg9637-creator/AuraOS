import AuraUI
import AuraGraphics
import AuraHardware

/// Типы каналов связи для совершения звонков
enum CallingProfile: Int {
    case cellular = 0   // Обычная мобильная связь (GSM/LTE)
    case voWiFi = 1     // Звонки по Wi-Fi (Voice over Wi-Fi)
    case voIP = 2       // Интернет-телефония (IP-связь через мобильные данные)
}

/// Глобальный конфигуратор настроек операционной системы AuraOS
class AuraSystemConfig {
    static let shared = AuraSystemConfig()
    
    // Текущий выбранный тип связи (по умолчанию — сотовая сеть)
    var activeCallingProfile: CallingProfile = .cellular
    var isAuraIDEnabled: Bool = true
    var selectedWallpaperTheme: String = "AuraDefaultDark"
}

class AuraSettingsApp: AuraApplication {
    let screenWidth: Float = 1170.0
    let screenHeight: Float = 2532.0
    
    override func onRender() {
        // 1. Фирменный фон настроек iOS (очень темно-серый, почти черный)
        AuraPainter.drawRect(x: 0, y: 0, width: screenWidth, height: screenHeight, color: Color(r: 0.05, g: 0.05, b: 0.05, a: 1.0))
        
        // 2. Большой заголовок приложения
        AuraPainter.drawText("Настройки", x: 60, y: 160, font: .systemCustom(size: 34, weight: .bold), color: .white)
        
        // 3. БЛОК 1: Профиль пользователя Aura ID (эффект стекла Aura Glass)
        drawProfileSection(y: 240)
        
        // 4. БЛОК 2: Выбор режима звонков (Интерактивная ячейка)
        drawCallingSettingsSection(y: 440)
    }
    
    private func drawProfileSection(y: Float) {
        AuraPainter.drawGlassRect(x: 40, y: y, width: screenWidth - 80, height: 160, cornerRadius: 24, blurRadius: 10, opacity: 0.15)
        
        // Аватарка аккаунта AuraOS
        AuraPainter.drawCircle(x: 110, y: y + 80, radius: 45, color: .systemBlue)
        AuraPainter.drawText("A", x: 95, y: y + 95, font: .systemBold(size: 24), color: .white)
        
        AuraPainter.drawText("Разработчик AuraOS", x: 190, y: y + 65, font: .systemBold(size: 18), color: .white)
        AuraPainter.drawText("GitHub Open-Source аккаунт", x: 190, y: y + 105, font: .systemRegular(size: 14), color: .gray)
    }
    
    private func drawCallingSettingsSection(y: Float) {
        let blockHeight: Float = 360.0
        AuraPainter.drawGlassRect(x: 40, y: y, width: screenWidth - 80, height: blockHeight, cornerRadius: 24, blurRadius: 10, opacity: 0.15)
        
        AuraPainter.drawText("ПРИОРИТЕТ ЗВОНКОВ", x: 60, y: y + 40, font: .systemBold(size: 13), color: .gray)
        
        // Отрисовываем три опции выбора
        drawRadioRow(title: "Мобильная связь (GSM/LTE)", index: 0, currentSelection: AuraSystemConfig.shared.activeCallingProfile.rawValue, y: y + 90)
        drawRadioRow(title: "Вызовы по Wi-Fi (VoWiFi)", index: 1, currentSelection: AuraSystemConfig.shared.activeCallingProfile.rawValue, y: y + 170)
        drawRadioRow(title: "Мобильный интернет (VoIP/Данные)", index: 2, currentSelection: AuraSystemConfig.shared.activeCallingProfile.rawValue, y: y + 250)
    }
    
    private func drawRadioRow(title: String, index: Int, currentSelection: Int, y: Float) {
        // Текст настройки
        AuraPainter.drawText(title, x: 80, y: y + 20, font: .systemRegular(size: 16), color: .white)
        
        // Кастомная галочка / чекбокс в стиле iOS (если выбрано — синий круг, если нет — серое кольцо)
        let circleX = screenWidth - 120.0
        if index == currentSelection {
            AuraPainter.drawCircle(x: circleX, y: y + 15, radius: 15, color: .systemBlue)
            AuraPainter.drawIcon(.checkmark, x: circleX + 5, y: y + 8, tint: .white)
        } else {
            AuraPainter.drawCircle(x: circleX, y: y + 15, radius: 15, color: .darkGray)
        }
        
        // Тонкий разделитель между строками (как в iOS)
        if index < 2 {
            AuraPainter.drawRect(x: 80, y: y + 55, width: screenWidth - 160, height: 1, color: Color(r: 0.15, g: 0.15, b: 0.15, a: 0.5))
        }
    }
    
    /// Обработка переключения настроек по нажатию пальца
    func handleTouch(x: Float, y: Float, event: TouchEvent) {
        guard event == .tap else { return }
        
        let startY: Float = 440.0 + 90.0
        
        // Вычисляем, на какую из строк выбора приоритета звонков нажал пользователь
        if x > 40 && x < (screenWidth - 40) {
            if y >= startY && y < startY + 80 {
                AuraSystemConfig.shared.activeCallingProfile = .cellular
                AuraHaptics.vibrate(.lightClick)
            } else if y >= startY + 80 && y < startY + 160 {
                AuraSystemConfig.shared.activeCallingProfile = .voWiFi
                AuraHaptics.vibrate(.lightClick)
            } else if y >= startY + 160 && y < startY + 240 {
                AuraSystemConfig.shared.activeCallingProfile = .voIP
                AuraHaptics.vibrate(.lightClick)
            }
        }
    }
}
