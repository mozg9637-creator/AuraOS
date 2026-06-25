import AuraUI
import AuraGraphics
import AuraHardware // Доступ к железу (динамик, подсветка)

struct ControlCenter {
    let screenWidth: Float = 1170.0
    let screenHeight: Float = 2532.0
    
    // Позиция шторки (0.0 — полностью скрыта, 1.0 — раскрыта на весь экран)
    var currentExpansion: Float = 0.0 
    
    /// Рендеринг элементов шторки
    func render() {
        guard currentExpansion > 0.0 else { return }
        
        // Высчитываем Y-координату панели на основе степени раскрытия
        let panelHeight = screenHeight * 0.75
        let panelY = -panelHeight + (panelHeight * currentExpansion)
        
        // 1. Задний фон: Тотальное размытие всего, что находится под шторкой
        AuraPainter.drawBlurOverlay(opacity: currentExpansion * 0.6, blurRadius: 40.0)
        
        // 2. Основной контейнер шторки (Матовое стекло Aura Glass)
        AuraPainter.drawGlassRect(
            x: 0, y: panelY,
            width: screenWidth, height: panelHeight,
            cornerRadius: 0.0, blurRadius: 20.0, opacity: 0.5
        )
        
        // Вычисляем отступ для элементов внутри движущейся шторки
        let contentY = panelY + 120.0
        
        // 3. Блок сетевых интерфейсов (Авиарежим, Wi-Fi, Bluetooth, Сотовые данные)
        drawNetworkBlock(x: 50, y: contentY)
        
        // 4. Плеер (Музыкальный виджет)
        drawMediaBlock(x: screenWidth - 530, y: contentY)
        
        // 5. Вертикальные интерактивные слайдеры (Яркость и Громкость)
        let slidersY = contentY + 340.0
        drawVerticalSlider(label: "Яркость", x: 50, y: slidersY, value: AuraHardware.Screen.getBrightness())
        drawVerticalSlider(label: "Звук", x: 300, y: slidersY, value: AuraHardware.Audio.getVolume())
    }
    
    private func drawNetworkBlock(x: Float, y: Float) {
        AuraPainter.drawGlassRect(x: x, y: y, width: 300, height: 300, cornerRadius: 36, blurRadius: 10, opacity: 0.3)
        
        // Рисуем сетку 2х2 из круглых зеленых/синих кнопок переключателей
        let isWifiOn = AuraHardware.Network.isWifiEnabled
        AuraPainter.drawCircle(x: x + 40, y: y + 40, radius: 45, color: isWifiOn ? .systemBlue : .darkGray)
        AuraPainter.drawIcon(.wifi, x: x + 62, y: y + 62, tint: .white)
        
        let isBtOn = AuraHardware.Network.isBluetoothEnabled
        AuraPainter.drawCircle(x: x + 170, y: y + 40, radius: 45, color: isBtOn ? .systemBlue : .darkGray)
        AuraPainter.drawIcon(.bluetooth, x: x + 192, y: y + 62, tint: .white)
    }
    
    private func drawMediaBlock(x: Float, y: Float) {
        AuraPainter.drawGlassRect(x: x, y: y, width: 480, height: 300, cornerRadius: 36, blurRadius: 10, opacity: 0.3)
        AuraPainter.drawText("Сейчас играет", x: x + 30, y: y + 30, font: .systemBold, color: .white)
        AuraPainter.drawIcon(.play, x: x + 220, y: y + 130, tint: .white)
    }
    
    private func drawVerticalSlider(label: String, x: Float, y: Float, value: Float) {
        let width: Float = 120.0
        let height: Float = 360.0
        
        // Подложка слайдера
        AuraPainter.drawGlassRect(x: x, y: y, width: width, height: height, cornerRadius: 28, blurRadius: 5, opacity: 0.2)
        
        // Заполненная часть слайдера (уровень громкости/яркости)
        let fillHeight = height * value
        let fillY = y + (height - fillHeight)
        AuraPainter.drawRoundedRect(x: x, y: fillY, width: width, height: fillHeight, cornerRadius: 28, color: .white)
        
        AuraPainter.drawText(label, x: x + 20, y: y + height + 20, font: .systemRegular(size: 14), color: .white)
    }
}
