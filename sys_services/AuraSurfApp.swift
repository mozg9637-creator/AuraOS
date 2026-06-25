import AuraUI
import AuraGraphics
import AuraNetwork // Наш сетевой стек (Wi-Fi / 5G)
import AuraWebKit  // Открытый движок рендеринга HTML/CSS, интегрированный в ядро

class AuraSurfApp: AuraApplication {
    let screenWidth: Float = 1170.0
    let screenHeight: Float = 2532.0
    
    // Состояние браузера
    private var currentURL: String = "https://github.com/aura-os"
    private var isPageLoading: Bool = false
    private var canGoBack: Bool = false
    
    // Текстура, в которую WebKit рендерит веб-страницу
    private var webPageTextureId: UInt32 = 0
    
    override func onLaunch() {
        print("🌌 AuraSurf: Инициализация движка WebKit...")
        // Выделяем память под отрисовку веб-страниц
        webPageTextureId = AuraWebKit.createBrowserContext(width: screenWidth, height: screenHeight - 340.0)
        
        // Загружаем домашнюю страницу
        loadWebPage(url: currentURL)
    }
    
    /// Логика отправки запроса через наш сетевой стек
    func loadWebPage(url: String) {
        self.isPageLoading = true
        self.currentURL = url
        
        print("AuraSurf: Запрос страницы \(url) через \(AuraNetworkStack.shared.activeInterface)")
        
        // Передаем URL в WebKit. Движок сам запросит данные через AuraNetworkStack,
        // распарсит HTML/CSS/JS и отрисует пиксели в нашу текстуру webPageTextureId
        AuraWebKit.loadURL(contextId: webPageTextureId, urlString: url) { success in
            self.isPageLoading = false
            self.canGoBack = AuraWebKit.canNavigateBack(contextId: self.webPageTextureId)
            
            if !success {
                print("AuraSurf: Ошибка загрузки страницы. Проверьте Wi-Fi или 5G.")
                AuraHaptics.vibrate(.error)
            } else {
                AuraHaptics.vibrate(.lightClick)
            }
        }
    }
    
    override func onRender() {
        // 1. Заливаем фон белым (базовый цвет для веб-страниц)
        AuraPainter.drawRect(x: 0, y: 0, width: screenWidth, height: screenHeight, color: .white)
        
        // 2. Отрисовываем саму веб-страницу (контент от WebKit)
        // Она занимает экран от статус-бара (y: 100) до панели управления (y: screenHeight - 240)
        AuraPainter.drawTexture(webPageTextureId, x: 0, y: 100, width: screenWidth, height: screenHeight - 340.0)
        
        // 3. Индикатор загрузки (полоса прогресса, если страница грузится)
        if isPageLoading {
            let progressWidth = screenWidth * Float(sin(AuraTime.getTicks() / 5.0) * 0.4 + 0.5)
            AuraPainter.drawRect(x: 0, y: 100, width: progressWidth, height: 4, color: .systemBlue)
        }
        
        // 4. Нижняя панель управления и адресная строка (iOS-style Матовое стекло)
        drawBottomBrowserPanel()
    }
    
    private func drawBottomBrowserPanel() {
        let panelHeight: Float = 240.0
        let panelY = screenHeight - panelHeight
        
        // Эффект Aura Glass для всей нижней панели
        AuraPainter.drawGlassRect(x: 0, y: panelY, width: screenWidth, height: panelHeight, cornerRadius: 0, blurRadius: 25, opacity: 0.4)
        
        // Скругленная поисковая/адресная строка посреди панели
        let searchBarX: Float = 160.0
        let searchBarWidth = screenWidth - 320.0
        AuraPainter.drawGlassRect(x: searchBarX, y: panelY + 30, width: searchBarWidth, height: 80, cornerRadius: 40, blurRadius: 5, opacity: 0.2)
        
        // Иконка замочка (SSL/HTTPS безопасность)
        AuraPainter.drawIcon(.lock_secure, x: searchBarX + 30, y: panelY + 55, tint: .gray)
        
        // Текст текущего URL адреса
        AuraPainter.drawText(currentURL, x: searchBarX + 80, y: panelY + 78, font: .systemRegular(size: 15), color: .black)
        
        // Элементы навигации (Кнопки "Назад", "Вперед", "Обновить", "Вкладки")
        let buttonsY = panelY + 150.0
        
        // Кнопка Назад
        let backColor: Color = canGoBack ? .black : .lightGray
        AuraPainter.drawIcon(.arrow_left, x: 60, y: buttonsY, tint: backColor)
        
        // Кнопка Обновить (справа от адресной строки)
        AuraPainter.drawIcon(.refresh, x: screenWidth - 110, y: panelY + 50, tint: .black)
        
        // Кнопка "Поделиться / Действие"
        AuraPainter.drawIcon(.share, x: screenWidth / 2 - 20, y: buttonsY, tint: .black)
        
        // Кнопка Вкладки (Квадратик)
        AuraPainter.drawIcon(.tabs_square, x: screenWidth - 100, y: buttonsY, tint: .black)
    }
    
    /// Обработка кликов по элементам интерфейса и ссылкам на сайтах
    func handleTouch(x: Float, y: Float, event: TouchEvent) {
        guard event == .tap else { 
            // Если пользователь скроллит (drag) — передаем координаты скролла в движок WebKit
            if case .drag(let deltaX, let deltaY) = event {
                AuraWebKit.scrollPage(contextId: webPageTextureId, deltaX: deltaX, deltaY: deltaY)
            }
            return 
        }
        
        let panelTopY = screenHeight - 240.0
        
        if y < panelTopY {
            // Если тапнули выше панели — передаем координаты клика внутрь сайта (клик по ссылкам, кнопкам на веб-странице)
            AuraWebKit.forwardClickToPage(contextId: webPageTextureId, clickX: x, clickY: y - 100)
        } else {
            // Обработка кликов по элементам управления самого браузера
            if x > 40 && x < 120 && y > (panelTopY + 130) {
                if canGoBack {
                    print("AuraSurf: Навигация назад")
                    AuraWebKit.goBack(contextId: webPageTextureId)
                }
            }
            
            // Клик по кнопке обновить
            if x > (screenWidth - 130) && x < (screenWidth - 70) && y > (panelTopY + 30) && y < (panelTopY + 100) {
                loadWebPage(url: currentURL)
            }
        }
    }
}
