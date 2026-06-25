import EmbeddedSwift
import AuraGraphics      // Низкоуровневый графический движок (Fluid Motion Engine)
import AuraHardware      // Работа с сенсорами устройства

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
    private var currentState: ShellState = .lockScreen
    
    // Физические параметры дисплея смартфона
    let screenWidth: Float = 1170.0
    let screenHeight: Float = 2532.0
    
    // Экземпляры системных подсистем и приложений
    private var lockScreen = LockScreen()
    private var homeScreen = HomeScreen()
    private var controlCenter = ControlCenter()
    private var taskManager = AppSwitcher() // Наш переименованный AuraTaskManager
    
    // Активное в данный момент приложение (Камера, Сообщения, Телефон или Настройки)
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
        
        // Подгружаем список процессов для менеджера многозадачности
        taskManager.loadActiveProcesses()
        
        // Запускаем бесконечный цикл рендеринга интерфейса (Render Loop)
        startRenderLoop()
    }
    
    /// Глобальный цикл отрисовки интерфейса (Отрабатывает каждые ~6.9 миллисекунд при 144 Гц)
    private func startRenderLoop() {
        while true {
            // 1. Очищаем предыдущий кадр из видеопамяти
            AuraDisplayDriver.clearFrame()
            
            // 2. Отрендерить текущую активную сцену на основе стейта системы
            switch currentState {
            case .lockScreen:
                lockScreen.render()
                
            case .homeScreen:
                homeScreen.render(atX: 0, y: 0)
                
            case .appSwitcherMode:
                taskManager.render()
                
            case .controlCenterMode:
                // Рендерим рабочий стол, а поверх него — выезжающую шторку
                homeScreen.render(atX: 0, y: 0)
                controlCenter.render()
                
            case .appRunning:
                if let app = activeApplication {
                    app.onRender()
                }
            }
            
            // 3. Поверх любой сцены ВСЕГДА рисуем динамический Статус-бар (кроме режима шторки на весь экран)
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
            // Отрендерить иконку "Нет сети"
            AuraPainter.drawIcon(.no_network, x: screenWidth - 160, y: 40, tint: .systemRed)
            
        case .wiFi(_, let strength):
            // Динамический выбор иконки Wi-Fi по уровню сигнала RSSI
            let wifiIcon = strength > -50 ? .wifi_full : .wifi_low
            AuraPainter.drawIcon(wifiIcon, x: screenWidth - 160, y: 40, tint: .white)
            
        case .cellular(_, let generation):
            // Рендер сотовой сети (Текст "5G" / "LTE" + Антенны)
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
    
    /// Метод принудительного обновления кадра (вызывается сетевым стеком при смене Wi-Fi -> 5G)
    func triggerStatusBarUpdate() {
        // Сигнал композитору пересчитать слой иконок сети в следующем кадре
    }
    
    /// Системный запуск приложения внутри оболочки
    func openApplication(_ app: AuraApplication) {
        self.activeApplication = app
        app.onLaunch()
        changeState(to: .appRunning)
    }
    
    /// Закрытие приложения и возврат на домашний экран (Аналог нажатия Home / Свайпа снизу)
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
            
            // Направляем тап в активный слой
            forwardTouchToActiveLayer(x: x, y: y, event: eventType)
            
        case .touchMove(let currentY):
            let deltaY = currentY - touchStartY
            let deltaX = x - touchStartX
            
            // Жест: Свайп сверху-справа экрана вниз (Вызов Центра Управления / Шторки)
            if touchStartY < 100 && touchStartX > (screenWidth - 300) && deltaY > 50 {
                isDraggingNotificationOrControl = true
                changeState(to: .controlCenterMode)
                controlCenter.currentExpansion = min(1.0, deltaY / 600.0) // 600px — полный ход открытия
                return
            }
            
            // Жест: Длинный свайп снизу экрана вверх (Вызов Многозадачности / App Switcher)
            if touchStartY > (screenHeight - 150) && deltaY < -200 {
                taskManager.loadActiveProcesses()
                changeState(to: .appSwitcherMode)
                return
            }
            
            // Обычная трансляция движения в интерфейсы
            if isDraggingNotificationOrControl {
                controlCenter.currentExpansion = min(1.0, max(0.0, deltaY / 600.0))
            } else {
                forwardTouchToActiveLayer(x: x, y: y, event: .drag(deltaX: deltaX, deltaY: deltaY))
            }
            
        case .touchUp:
            if isDraggingNotificationOrControl {
                // Доводчик шторки: если открыли больше чем наполовину — фиксируем, иначе закрываем
                if controlCenter.currentExpansion > 0.5 {
                    controlCenter.currentExpansion = 1.0
                } else {
                    controlCenter.currentExpansion = 0.0
                    changeState(to: .homeScreen)
                }
                isDraggingNotificationOrControl = false
                return
            }
            
            forwardTouchToActiveLayer(x: x, y: y, event: eventType)
        default:
            break
        }
    }
    
    /// Внутренняя маршрутизация тапов в зависимости от того, что сейчас открыто на экране телефоне
    private func forwardTouchToActiveLayer(x: Float, y: Float, event: TouchEvent) {
        switch currentState {
        case .lockScreen:
            lockScreen.handleTouch(x: x, y: y, event: event)
        case .homeScreen:
            homeScreen.handleGlobalTouch(x: x, y: y, event: event)
        case .appSwitcherMode:
            taskManager.handleTouch(x: x, y: y, event: event)
        case .controlCenterMode:
            controlCenter.handleTouch(x: x, y: y, event: event)
        case .appRunning:
            if let app = activeApplication as? CameraApp {
                app.handleTouch(x: x, y: y, event: event)
            } else if let app = activeApplication as? AuraMessagesApp {
                app.handleTouch(x: x, y: y, event: event)
            } else if let app = activeApplication as? AuraSettingsApp {
                app.handleTouch(x: x, y: y, event: event)
            } else if let app = activeApplication as? AuraPhoneApp {
                app.handleTouch(x: x, y: y, event: event)
            }
        }
    }
}
