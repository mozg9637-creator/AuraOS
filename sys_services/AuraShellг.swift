import EmbeddedSwift
import AuraGraphics      // Низкоуровневый графический движок (Fluid Motion Engine)
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
    
    // Текущий режим работы интерфейса
    private var currentState: ShellState = .homeScreen // Сразу загружаемся на рабочий стол
    
    // Физические параметры дисплея смартфона
    let screenWidth: Float = 1170.0
    let screenHeight: Float = 2532.0
    
    // Экземпляры системных подсистем и интерфейсов
    private var taskManager = AppSwitcher() // Наш менеджер задач AuraTaskManager
    
    // Активное в данный момент приложение
    private var activeApplication: AuraApplication? = nil
    
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
        
        // 🔥 ЭКРАН ЗАГРУЗКИ: Отрисовываем твой фирменный логотип-маскот перед запуском системы
        renderBootSplash()
        
        // Подгружаем список процессов для менеджера многозадачности
        taskManager.loadActiveProcesses()
        
        // Запускаем бесконечный цикл рендеринга интерфейса (Render Loop)
        startRenderLoop()
    }
    
    /// Отрисовка кастомного Boot Logo (Троллфейс из image_842257.png)
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
        AuraTime.delay(ms: 2000) // Задержка в 2 секунды, чтобы рассмотреть логотип при буте
    }
    
    /// Глобальный цикл отрисовки интерфейса (Отрабатывает каждые ~6.9 миллисекунд при 144 Гц)
    private func startRenderLoop() {
        while true {
            // 1. Очищаем предыдущий кадр из видеопамяти
            AuraDisplayDriver.clearFrame()
            
            // 2. Отрендерить текущую активную сцену на основе стейта системы
            switch currentState {
            case .lockScreen:
                // Временная заглушка, пока нет файла LockScreen.swift
                AuraPainter.drawText("Lock Screen (Swipe Up to Unlock)", x: 200, y: 500, font: .systemBold(size: 24), color: .white)
                
            case .homeScreen:
                // Временная заглушка: просто чистый рабочий стол с текстом
                AuraPainter.drawText("AuraOS Home Screen", x: 300, y: 400, font: .systemBold(size: 32), color: .cyan)
                AuraPainter.drawText("Apps are ready.", x: 300, y: 460, font: .systemRegular(size: 18), color: .gray)
                
            case .appSwitcherMode:
                taskManager.render()
                
            case .controlCenterMode:
                // Временная заглушка вместо ControlCenter.swift
                AuraPainter.drawText("Control Center Active", x: 350, y: 200, font: .systemBold(size: 24), color: .green)
                
            case .appRunning:
                if let app = activeApplication {
                    app.onRender()
                }
            }
            
            // 3. Поверх любой сцены ВСЕГДА рисуем динамический Статус-бар
            if currentState != .controlCenterMode {
                renderSystemStatusBar()
            }
            
            // 4. Выводим готовый кадр на экран телефона (Page Flipping)
            AuraDisplayDriver.swapBuffers()
        }
    }
    
    /// Динамический статус-бар (Интеграция с AuraNetworkStack в стиле iOS)
    private func renderSystemStatusBar() {
        // Системное время (слева)
        AuraPainter.drawText("20:42", x: 60, y: 40, font: .systemBold(size: 15), color: .white)
        
        // Опрос сетевого стека (справа)
        let netType = AuraNetworkStack.shared.activeInterface
        
        switch netType {
        case .none:
            AuraPainter.drawIcon(.no_network, x: screenWidth - 160, y: 40, tint: .systemRed)
            
        case .wiFi(_, let strength):
            let wifiIcon = strength > -50 ? .wifi_full : .wifi_low
            AuraPainter.drawIcon(wifiIcon, x: screenWidth - 160, y: 40, tint: .white)
            
        case .cellular(_, let generation):
            AuraPainter.drawText(generation, x: screenWidth - 210, y: 43, font: .systemBold(size: 12), color: .white)
            AuraPainter.drawIcon(.cellular_bars, x: screenWidth - 160, y: 40, tint: .white)
        }
        
        // Индикатор батареи
        AuraPainter.drawIcon(.battery, x: screenWidth - 80, y: 40, tint: .white)
    }
    
    /// Публичный метод переключения оконных режимов
    func changeState(to newState: ShellState) {
        print("AuraOS Shell: Смена состояния экрана на [\(newState)]")
        self.currentState = newState
        AuraHaptics.vibrate(.lightClick) // Мягкий тактильный клик при переходах
    }
    
    /// Метод принудительного обновления кадра
    func triggerStatusBarUpdate() {}
    
    /// Системный запуск приложения внутри оболочки
    func openApplication(_ app: AuraApplication) {
        self.activeApplication = app
        app.onLaunch()
        changeState(to: .appRunning)
    }
    
    /// Закрытие приложения и возврат на домашний экран
    func closeCurrentApplication() {
        self.activeApplication = nil
        changeState(to: .homeScreen)
    }
    
    // ==============================================================================
    // 🎛️ Глобальный Диспетчер Тачскрина (Touch & Gestures Router)
    // ==============================================================================
    
    func handleTouch(x: Float, y: Float, eventType: TouchEvent) {
        switch eventType {
        case .touchDown:
            touchStartX = x
            touchStartY = y
            isDraggingNotificationOrControl = false
            forwardTouchToActiveLayer(x: x, y: y, event: eventType)
            
        case .touchMove(let currentY):
            let deltaY = currentY - touchStartY
            let deltaX = x - touchStartX
            
            if touchStartY < 100 && touchStartX > (screenWidth - 300) && deltaY > 50 {
                isDraggingNotificationOrControl = true
                changeState(to: .controlCenterMode)
                return
            }
            
            if touchStartY > (screenHeight - 150) && deltaY < -200 {
                taskManager.loadActiveProcesses()
                changeState(to: .appSwitcherMode)
                return
            }
            
            if !isDraggingNotificationOrControl {
                forwardTouchToActiveLayer(x: x, y: y, event: .drag(deltaX: deltaX, deltaY: deltaY))
            }
            
        case .touchUp:
            if isDraggingNotificationOrControl {
                isDraggingNotificationOrControl = false
                return
            }
            forwardTouchToActiveLayer(x: x, y: y, event: eventType)
        default:
            break
        }
    }
    
    /// Внутренняя маршрутизация тапов в зависимости от открытого софта
    private func forwardTouchToActiveLayer(x: Float, y: Float, event: TouchEvent) {
        switch currentState {
        case .appSwitcherMode:
            taskManager.handleTouch(x: x, y: y, event: event)
        case .appRunning:
            if let app = activeApplication as? CameraApp { app.handleTouch(x: x, y: y, event: event) }
            else if let app = activeApplication as? AuraMessagesApp { app.handleTouch(x: x, y: y, event: event) }
            else if let app = activeApplication as? AuraSettingsApp { app.handleTouch(x: x, y: y, event: event) }
            else if let app = activeApplication as? AuraPhoneApp { app.handleTouch(x: x, y: y, event: event) }
            else if let app = activeApplication as? AuraSurfApp { app.handleTouch(x: x, y: y, event: event) }
            else if let app = activeApplication as? AuraPhotosApp { app.handleTouch(x: x, y: y, event: event) }
        default:
            break
        }
    }
}
