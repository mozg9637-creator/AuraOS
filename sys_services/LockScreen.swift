import AuraUI
import AuraGraphics
import AuraSecurity // Модуль биометрии Aura ID

struct LockScreen {
    let screenWidth: Float = 1170.0
    let screenHeight: Float = 2532.0
    
    // Координаты для анимации свайпа вверх
    private var dragOffsetY: Float = 0.0
    private var isDragging: Bool = false
    
    /// Основной цикл отрисовки Экрана Блокировки
    func render() {
        // 1. Отрисовка обоев с эффектом глубины (Часы будут «за» объектом на фото)
        AuraPainter.drawWallpaper(withDepthEffect: true)
        
        // 2. Получаем текущее время от системного таймера ядра
        let currentTime = AuraTime.getCurrentTime() // Возвращает структуру (hours, minutes, date)
        
        // 3. Рендерим Часы и Дату с кастомным шрифтом Aura San Francisco
        let timeString = String(format: "%02d:%02d", currentTime.hours, currentTime.minutes)
        
        // Отрисовка подложки времени (чуть размытой, если включен эффект глубины)
        AuraPainter.drawText(
            timeString, 
            x: screenWidth / 2 - 180, 
            y: 320 + dragOffsetY, // Смещается при свайпе
            font: .systemCustom(size: 96, weight: .thin), 
            color: .white.withOpacity(0.9)
        )
        
        // Отрисовка Даты над часами
        AuraPainter.drawText(
            currentTime.dateString,
            x: screenWidth / 2 - 100,
            y: 200 + dragOffsetY,
            font: .systemRegular(size: 20),
            color: .white
        )
        
        // 4. Индикатор Aura ID (Иконка замочка, которая плавно открывается)
        drawAuthStatusIndicator()
        
        // 5. Нижние быстрые кнопки: Камера и Фонарик (Матовое стекло)
        drawQuickAccessButtons()
        
        // 6. Подсказка внизу экрана: "Смахните вверх, чтобы разблокировать"
        if !isDragging {
            let pulseOpacity = Float(sin(AuraTime.getTicks() / 10.0) * 0.5 + 0.5)
            AuraPainter.drawText(
                "Смахните вверх для разблокировки", 
                x: screenWidth / 2 - 150, 
                y: screenHeight - 100, 
                font: .systemRegular(size: 16), 
                color: .white.withOpacity(pulseOpacity)
            )
            AuraPainter.drawHomeBar(x: screenWidth / 2 - 70, y: screenHeight - 30, tint: .white)
        }
    }
    
    private func drawAuthStatusIndicator() {
        let lockIcon = AuraSecurityManager.isFaceRecognized ? "icon_lock_open" : "icon_lock_closed"
        AuraPainter.drawIcon(
            named: lockIcon, 
            x: screenWidth / 2 - 24, 
            y: 120 + dragOffsetY, 
            tint: .white
        )
    }
    
    private func drawQuickAccessButtons() {
        let btnSize: Float = 100.0
        let bottomY = screenHeight - 220 + dragOffsetY
        
        // Кнопка Фонарика (слева)
        AuraPainter.drawGlassCircle(x: 80, y: bottomY, radius: btnSize / 2, opacity: 0.3)
        AuraPainter.drawIcon(.flashlight, x: 80 + 32, y: bottomY + 32, tint: .white)
        
        // Кнопка Камеры (справа)
        AuraPainter.drawGlassCircle(x: screenWidth - 180, y: bottomY, radius: btnSize / 2, opacity: 0.3)
        AuraPainter.drawIcon(.camera, x: screenWidth - 180 + 32, y: bottomY + 32, tint: .white)
    }
    
    /// Обработка жестов на Экране Блокировки
    mutating func handleTouch(x: Float, y: Float, event: TouchEvent) {
        switch event {
        case .touchDown:
            if y > screenHeight - 150 { // Захват нижней полосы (Home Bar)
                isDragging = true
            }
        case .touchMove(let currentY):
            if isDragging {
                // Высчитываем сдвиг экрана вверх (отрицательное значение)
                let deltaY = currentY - (screenHeight - 100)
                if deltaY < 0 {
                    dragOffsetY = deltaY
                }
            }
        case .touchUp:
            isDragging = false
            // Если пользователь свайпнул вверх больше чем на 30% экрана
            if dragOffsetY < -(screenHeight * 0.3) {
                attemptUnlock()
            } else {
                // Плавный возврат экрана на место (пружинная анимация Fluid Motion)
                animateSpringBack()
            }
        default:
            break
        }
    }
    
    private mutating func attemptUnlock() {
        if AuraSecurityManager.isFaceRecognized {
            print("AuraOS LockScreen: Успешная биометрия. Переход на HomeScreen.")
            AuraShell.shared.changeState(to: .homeScreen)
        } else {
            print("AuraOS LockScreen: Доступ запрещен. Запрос пароля.")
            AuraHaptics.vibrate(.error) // Тройная вибрация отказа
            animateSpringBack()
        }
    }
    
    private mutating func animateSpringBack() {
        // В реальном движке здесь запускается интерполятор физики пружин
        dragOffsetY = 0.0
    }
}
