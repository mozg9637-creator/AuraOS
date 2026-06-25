import EmbeddedSwift
import AuraGraphics // Наш низкоуровневый графический драйвер ядра

/// Статусы жизненного цикла оконного менеджера AuraOS
enum ShellState {
    case lockScreen
    case homeScreen
    case appRunning
}

class AuraShell {
    static let shared = AuraShell()
    
    private var currentState: ShellState = .homeScreen
    private var activeAppWindow: AuraWindow? = nil
    
    // Разрешение экрана (базовое для большинства современных телефонов)
    let screenWidth: Float = 1170.0
    let screenHeight: Float = 2532.0
    
    /// Точка входа в графическую оболочку
    func bootShell() {
        print("AuraOS UI: Инициализация Fluid Motion Engine...")
        
        // Запрашиваем доступ к кадровому буферу дисплея
        guard AuraDisplayDriver.initialize(width: screenWidth, height: screenHeight) else {
            panic("Критическая ошибка: Дисплей не отвечает.")
        }
        
        // Включаем вертикальную синхронизацию (V-Sync) на 144 Гц
        AuraDisplayDriver.setRefreshRate(144)
        
        // Запускаем бесконечный цикл рендеринга интерфейса (Render Loop)
        startRenderLoop()
    }
    
    private func startRenderLoop() {
        while true {
            // Очищаем экран перед новым кадром (черный фон)
            AuraDisplayDriver.clearFrame()
            
            // Отрисовываем текущее состояние графической оболочки
            switch currentState {
            case .lockScreen:
                renderLockScreen()
            case .homeScreen:
                // Отрисовка рабочего стола
                HomeScreen().render(atX: 0, y: 0)
            case .appRunning:
                if let app = activeAppWindow {
                    app.render()
                }
            }
            
            // Рендерим системные элементы поверх всего (Статус-бар, батарея, Wi-Fi)
            renderSystemStatusBar()
            
            // Выводим готовый кадр на физический экран телефона
            AuraDisplayDriver.swapBuffers()
        }
    }
    
    private func renderSystemStatusBar() {
        // Отрисовка часов, заряда батареи и сети вверху экрана
        AuraPainter.drawText("20:42", x: 60, y: 40, font: .systemBold, color: .white)
        AuraPainter.drawIcon(.battery, x: screenWidth - 100, y: 40, tint: .white)
        AuraPainter.drawIcon(.wifi, x: screenWidth - 140, y: 40, tint: .white)
    }
    
    /// Обработчик нажатий на экран (передается из драйвера тачскрина в ядре)
    func handleTouch(x: Float, y: Float, eventType: TouchEvent) {
        if currentState == .homeScreen {
            // Передаем координаты нажатия рабочему столу
            HomeScreen().handleGlobalTouch(x: x, y: y, event: eventType)
        }
    }
}
