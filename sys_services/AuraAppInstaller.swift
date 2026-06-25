/// Обработка кликов по элементам интерфейса, ссылкам на сайтах и скачиванию софта
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
            // 1. Проверяем, на какую ссылку нажал пользователь внутри WebKit
            let clickedLink = AuraWebKit.getLinkAtCoordinates(contextId: webPageTextureId, tapX: x, tapY: y - 100)
            
            // 🔥 ПЕРЕХВАТ СКАЧИВАНИЯ: Если ссылка ведет на пакет приложения AuraOS (.apkg)
            if clickedLink.hasSuffix(".apkg") {
                print("📥 AuraSurf: Обнаружена ссылка на приложение! Инициирую скачивание...")
                self.isPageLoading = true // Показываем полосу прогресса загрузки
                
                AuraPackageManager.shared.installApp(fromUrl: clickedLink) { success in
                    self.isPageLoading = false
                    if success {
                        print("🎉 AuraSurf: Приложение успешно скачано и установлено!")
                        // Опционально: можно автоматически выйти на рабочий стол, чтобы пользователь увидел иконку
                        AuraShell.shared.closeCurrentApplication()
                    } else {
                        print("⚠️ AuraSurf: Ошибка при установке приложения.")
                    }
                }
                return // Прерываем обычный переход по ссылке, так как мы обрабатываем файл сами
            }
            
            // Если это обычная ссылка (не приложение) — просто даем WebKit команду перейти на нее
            AuraWebKit.forwardClickToPage(contextId: webPageTextureId, clickX: x, clickY: y - 100)
            
            // Обновляем адресную строку новым URL, на который перешел пользователь
            self.currentURL = AuraWebKit.getCurrentURL(contextId: webPageTextureId)
            
        } else {
            // 2. Обработка кликов по элементам управления самого браузера (Назад, Обновить и т.д.)
            if x > 40 && x < 120 && y > (panelTopY + 130) {
                if canGoBack {
                    AuraWebKit.goBack(contextId: webPageTextureId)
                    self.currentURL = AuraWebKit.getCurrentURL(contextId: webPageTextureId)
                }
            }
            
            // Клик по кнопке обновить
            if x > (screenWidth - 130) && x < (screenWidth - 70) && y > (panelTopY + 30) && y < (panelTopY + 100) {
                loadWebPage(url: currentURL)
            }
        }
    }
