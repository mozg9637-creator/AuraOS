import AuraUI
import AuraGraphics
import AuraKernel // Доступ к менеджеру процессов ядра

struct AppCard {
    let processId: UInt64
    let appName: String
    let iconAsset: String
    let snapshotTextureId: UInt32 // Текстура последнего кадра приложения
}

class AppSwitcher {
    let screenWidth: Float = 1170.0
    let screenHeight: Float = 2532.0
    
    // Список открытых в данный момент приложений
    private var activeApps: [AppCard] = []
    
    // Индекс карточки, которая находится по центру экрана
    private var focusedCardIndex: Int = 0
    private var scrollOffset: Float = 0.0
    
    /// Инициализация меню многозадачности
    func loadActiveProcesses() {
        activeApps.removeAll()
        
        // Запрашиваем у ядра Rust список живых процессов
        let processes = AuraKernel.ProcessManager.getRunningApplications()
        
        for proc in processes {
            activeApps.append(AppCard(
                processId: proc.id,
                appName: proc.name,
                iconAsset: proc.icon,
                snapshotTextureId: proc.lastFrameSnapshotId
            ))
        }
        // Фокусируемся на последнем запущенном приложении
        focusedCardIndex = max(0, activeApps.count - 1)
    }
    
    /// Рендеринг сцены многозадачности
    func render() {
        // 1. Системные обои на фоне слегка размываются
        AuraPainter.drawWallpaper(blurred: true)
        
        guard !activeApps.isEmpty else {
            AuraPainter.drawText("Нет открытых приложений", x: screenWidth/2 - 150, y: screenHeight/2, font: .systemRegular(size: 18), color: .lightGray)
            return
        }
        
        // Размеры карточки приложения (пропорции экрана телефона, но уменьшенные)
        let cardWidth: Float = 700.0
        let cardHeight: Float = 1514.0
        let cardY = (screenHeight - cardHeight) / 2
        
        // 2. Отрисовка ленты карточек с каскадным эффектом (iOS-style карусель)
        for (index, app) in activeApps.enumerated() {
            // Вычисляем позицию карточки на основе скролла
            let indexOffset = Float(index - focusedCardIndex)
            let baseX = (screenWidth - cardWidth) / 2
            let cardX = baseX + (indexOffset * (cardWidth + 60.0)) + scrollOffset
            
            // Пропускаем рендеринг, если карточка далеко за пределами экрана
            if cardX < -cardWidth || cardX > screenWidth { continue }
            
            // Эффект перспективы: боковые карточки чуть меньше центральной
            let distanceFromCenter = abs(cardX - baseX)
            let scale = max(0.85, 1.0 - (distanceFromCenter / screenWidth) * 0.15)
            
            // Отрисовка тени карточки для создания глубины
            AuraPainter.drawShadowRect(x: cardX, y: cardY, width: cardWidth, height: cardHeight, radius: 40.0 * scale)
            
            // Отрисовка скриншота запущенного приложения со скругленными углами
            AuraPainter.drawScaledTexture(
                app.snapshotTextureId,
                x: cardX, y: cardY,
                width: cardWidth, height: cardHeight,
                scale: scale,
                cornerRadius: 40.0
            )
            
            // Отрисовка иконки и названия приложения НАД карточкой
            let headerY = cardY - 80.0
            AuraPainter.drawIcon(named: app.iconAsset, x: cardX + 20, y: headerY, tint: .white)
            AuraPainter.drawText(app.appName, x: cardX + 80, y: headerY + 10, font: .systemBold(size: 16), color: .white)
        }
        
        // 3. Нижняя полоса Home Bar
        AuraPainter.drawHomeBar(x: screenWidth / 2 - 70, y: screenHeight - 30, tint: .white)
    }
    
    /// Обработка жестов скролла и закрытия приложений (свайп вверх)
    func handleTouch(x: Float, y: Float, event: TouchEvent) {
        switch event {
        case .drag(let deltaX, let deltaY):
            // Горизонтальный свайп — листаем карточки
            if abs(deltaX) > abs(deltaY) {
                scrollOffset += deltaX
            } 
            // Вертикальный свайп вверх — закрываем выбранное приложение
            else if deltaY < -50.0 && abs(scrollOffset) < 20.0 {
                swipeUpToCloseApp(index: focusedCardIndex)
            }
            
        case .touchUp:
            // Инерционный доводчик: выравниваем ближайшую карточку по центру (iOS Snapping)
            snapToNearestCard()
            
        default:
            break
        }
    }
    
    private func snapToNearestCard() {
        let cardWidth: Float = 700.0
        let threshold = (cardWidth + 60.0) / 2
        
        if scrollOffset < -threshold && focusedCardIndex < activeApps.count - 1 {
            focusedCardIndex += 1
        } else if scrollOffset > threshold && focusedCardIndex > 0 {
            focusedCardIndex -= 1
        }
        
        // Сбрасываем временное смещение, запуская пружинную анимацию ядра Fluid Motion
        scrollOffset = 0.0
    }
    
    private func swipeUpToCloseApp(index: Int) {
        let appToKill = activeApps[index]
        print("AuraOS Менеджер: Убийство процесса ID \(appToKill.processId) (\(appToKill.appName))")
        
        // Отправляем ядру Rust команду на жесткое завершение процесса и очистку его оперативной памяти
        AuraKernel.ProcessManager.killProcess(id: appToKill.processId)
        
        // Тактильный отклик (вибрация щелчка)
        AuraHaptics.vibrate(.lightClick)
        
        // Удаляем карточку из интерфейса с красивой анимацией вылета вверх
        activeApps.remove(at: index)
        
        // Корректируем фокус карусели
        if focusedCardIndex >= activeApps.count && !activeApps.isEmpty {
            focusedCardIndex = activeApps.count - 1
        }
    }
}
