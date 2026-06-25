import AuraUI
import AuraGraphics

/// Структура, описывающая иконку приложения на рабочем столе
struct AppDescriptor {
    let id: String
    let name: String
    let iconAsset: String
    let bundlePath: String
}

struct HomeScreen {
    // Список приложений по умолчанию
    let apps: [AppDescriptor] = [
        AppDescriptor(id: "phone", name: "Телефон", iconAsset: "icon_phone", bundlePath: "/sys/apps/phone"),
        AppDescriptor(id: "safari", name: "Браузер", iconAsset: "icon_browser", bundlePath: "/sys/apps/browser"),
        AppDescriptor(id: "messages", name: "Сообщения", iconAsset: "icon_msg", bundlePath: "/sys/apps/msg"),
        AppDescriptor(id: "music", name: "Музыка", iconAsset: "icon_music", bundlePath: "/sys/apps/music"),
        AppDescriptor(id: "settings", name: "Настройки", iconAsset: "icon_settings", bundlePath: "/sys/apps/settings")
    ]
    
    // Параметры сетки иконок (как в iOS: 4 колонки)
    let columns = 4
    let iconSize: Float = 120.0
    let padding: Float = 45.0
    let startY: Float = 180.0
    
    /// Основная функция отрисовки интерфейса рабочего стола
    func render(atX startX: Float, y: Float) {
        // 1. Рисуем размытый задний фон (Обои с эффектом Blur)
        AuraPainter.drawWallpaper(blurred: false)
        
        // 2. Отрисовываем сетку приложений
        for (index, app) in apps.enumerated() {
            let row = index / columns
            let col = index % columns
            
            // Высчитываем точные физические координаты для каждой иконки на экране
            let posX = padding + Float(col) * (iconSize + padding)
            let posY = startY + Float(row) * (iconSize + padding + 30) // 30px подпись названия
            
            drawAppIcon(app: app, x: posX, y: posY)
        }
        
        // 3. Рисуем нижний Док-бар (Dock) для избранных приложений с эффектом матового стекла (Aura Glass)
        drawDock()
    }
    
    private func drawAppIcon(app: AppDescriptor, x: Float, y: Float) {
        // Отрисовка иконки со скруглением углов iOS (Smooth Corner Radius)
        AuraPainter.drawRoundedImage(
            named: app.iconAsset,
            x: x, y: y,
            width: iconSize, height: iconSize,
            cornerRadius: 28.0 // Фирменный радиус скругления иконок
        )
        
        // Центрируем и рисуем текст под иконкой
        let textX = x + (iconSize / 2) - 30
        let textY = y + iconSize + 15
        AuraPainter.drawText(app.name, x: textX, y: textY, font: .systemRegular(size: 14), color: .white)
    }
    
    private func drawDock() {
        let dockWidth: Float = 1080.0
        let dockHeight: Float = 190.0
        let dockX: Float = (1170.0 - dockWidth) / 2
        let dockY: Float = 2532.0 - dockHeight - 50 // 50px отступ снизу экрана
        
        // Отрендерить эффект "Aura Glass" (Размытие подложки в реальном времени)
        AuraPainter.drawGlassRect(
            x: dockX, y: dockY,
            width: dockWidth, height: dockHeight,
            cornerRadius: 45.0,
            blurRadius: 30.0,
            opacity: 0.4
        )
        
        // Внутри реального Дока мы бы также отрисовали 4 главных закрепленных приложения
    }
    
    /// Обработка тапов по иконкам приложений
    func handleGlobalTouch(x: Float, y: Float, event: TouchEvent) {
        guard event == .tap else { return }
        
        // Проверяем, попал ли палец пользователя в координаты какой-либо иконки
        for (index, app) in apps.enumerated() {
            let row = index / columns
            let col = index % columns
            
            let posX = padding + Float(col) * (iconSize + padding)
            let posY = startY + Float(row) * (iconSize + padding + 30)
            
            if x >= posX && x <= (posX + iconSize) && y >= posY && y <= (posY + iconSize) {
                print("AuraOS Launcher: Запуск приложения -> \(app.name) [\(app.bundlePath)]")
                AuraProcessManager.launchApp(from: app.bundlePath)
                break
            }
        }
    }
}
