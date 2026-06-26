import EmbeddedSwift
import AuraGraphics      // Низкоуровневый графический движок
import AuraHardware      // Работа с сенсорами и экраном устройства

/// Глобальные состояния операционной системы AuraOS
enum ShellState {
    case lockScreen
    case homeScreen
    case appSwitcherMode
    case controlCenterMode
    case appRunning
}

/// Главный системный композитор и менеджер окон AuraOS
class AuraShell {
    static let shared = AuraShell()
    
    // Текущий режим работы интерфейса (изменяемый var)
    private var currentState: ShellState = .homeScreen
    
    // Физические параметры дисплея смартфона
    let screenWidth: Float = 1170.0
    let screenHeight: Float = 2532.0
    
    // Активное в данный момент приложение
    private var activeApplication: Any? = nil
    
    // Переменные для отслеживания жестов свайпа
    private var touchStartX: Float = 0.0
    private var touchStartY: Float = 0.0
    private var isDraggingNotificationOrControl: Bool = false
    
    private init() {}
    
    /// Главная точка входа графической оболочки (вызывается из ядра Rust)
    func bootShell() {
        print("🌌 AuraOS UI: Запуск Fluid Motion Engine...")
        
        // Резервируем кадровый буфер (Framebuffer) дисплея через видеочип
        guard AuraDisplayDriver.initialize(width: screenWidth, height: screenHeight) else {
            print("Критический сбой: Видеочип дисплея не отвечает!")
            return
        }
        
        // Форсируем аппаратную вертикальную синхронизацию на 144 Гц
        AuraDisplayDriver.setRefreshRate(144)
        
        // 🔥 ЭКРАН ЗАГРУЗКИ: Логотип перед запуском системы
        renderBootSplash()
        
        // Запускаем бесконечный цикл рендеринга интерфейса (Render Loop)
        startRenderLoop()
    }
    
    /// Отрисовка кастомного Boot Logo
    private func renderBootSplash() {
        AuraDisplayDriver.clearFrame()
        
        // Загружаем текстуру твоего неонового логотипа
        let logoTextureId = AuraGraphics.TextureManager.loadPNG("image_842257.png")
        let logoSize: Float = 512.0
        
        // Выводим логотип строго по центру черного экрана
        AuraPainter.drawTexture(
            logoTextureId, 
            x: (screenWidth - logoSize) / 2, 
            y: (screenHeight - logoSize) / 2, 
            width: logoSize, 
            height: logoSize
        )
        
        // Системный статус загрузки снизу
        AuraPainter.drawText("AuraOS is loading...", x: screenWidth / 2 - 100, y: screenHeight - 300, font: .systemRegular(size: 16), color: .gray)
        
        AuraDisplayDriver.swapBuffers()
        AuraTime.delay(ms: 2000) // Задержка в 2 секунды
    }
    
    /// Глобальный цикл отрисовки интерфейса
    private func startRenderLoop() {
        while true {
            AuraDisplayDriver.clearFrame()
            
            switch currentState {
            case .lockScreen:
                AuraPainter.drawText("Lock Screen (Swipe Up to Unlock)", x: 200, y: 500, font: .systemBold(size: 24), color: .white)
                
            case .homeScreen:
                AuraPainter.drawText("AuraOS Home Screen", x: 300, y: 400, font: .systemBold(size: 32), color: .cyan)
                AuraPainter.drawText("Apps are ready.", x: 300, y: 460, font: .systemRegular(size: 18), color: .gray)
                
            case .appSwitcherMode:
                AuraPainter.drawText("App Switcher Active", x: 300, y: 300, font: .systemBold(size: 24), color: .orange)
                
            case .controlCenterMode:
                AuraPainter.drawText("Control Center Active", x: 350, y: 200, font: .systemBold(size: 24), color: .green)
                
            case .appRunning:
                AuraPainter.drawText("Application Running...", x: 300, y: 400, font: .systemRegular(size: 20), color: .white)
            }
            
            // Поверх любой сцены ВСЕГДА рисуем динамический Статус-бар
            if currentState != .controlCenterMode {
                renderSystemStatusBar()
            }
            
            AuraDisplayDriver.swapBuffers()
        }
    }
    
    /// Динамический статус-бар (Интеграция с AuraNetworkStack в стиле iOS)
    private func renderSystemStatusBar() {
        AuraPainter.drawText("20:42", x: 60, y: 40, font: .systemBold(size: 15), color: .white)
        
        let netType = AuraNetworkStack.shared.activeInterface
        
        switch netType {
        case .none:
            AuraPainter.drawIcon(.no_network, x: screenWidth - 160, y: 40, tint: .systemRed)
        case .wiFi(_, _):
            AuraPainter.drawIcon(.wifi_full, x: screenWidth - 160, y: 40, tint: .white)
        case .cellular(_, _):
            AuraPainter.drawIcon(.cellular_bars, x: screenWidth - 160, y: 40, tint: .white)
        }
        
        AuraPainter.drawIcon(.battery, x: screenWidth - 80, y: 40, tint: .white)
    }
    
    func changeState(to newState: ShellState) {
        self.currentState = newState
        AuraHaptics.vibrate(.lightClick)
    }
    
    func triggerStatusBarUpdate() {}
    
    func closeCurrentApplication() {
        self.activeApplication = nil
        changeState(to: .homeScreen)
    }
    
    func handleTouch(x: Float, y: Float, eventType: TouchEvent) {
        switch eventType {
        case .touchDown:
            touchStartX = x
            touchStartY = y
            isDraggingNotificationOrControl = false
            
        case .touchMove(let currentY):
            let deltaY = currentY - touchStartY
            
            if touchStartY < 100 && touchStartX > (screenWidth - 300) && deltaY > 50 {
                isDraggingNotificationOrControl = true
                changeState(to: .controlCenterMode)
                return
            }
            
            if touchStartY > (screenHeight - 150) && deltaY < -200 {
                changeState(to: .appSwitcherMode)
                return
            }
            
        case .touchUp:
            if isDraggingNotificationOrControl {
                isDraggingNotificationOrControl = false
                return
            }
        default:
            break
        }
    }
}
