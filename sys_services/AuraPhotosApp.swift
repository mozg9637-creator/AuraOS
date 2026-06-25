import AuraUI
import AuraGraphics
import AuraStorage // Наша подсистема ядра для работы с файлами (VFS)

/// Структура метаданных отдельной фотографии
struct PhotoAsset {
    let fileId: UInt64
    let localPath: String
    let creationTimestamp: UInt64
    let thumbnailTextureId: UInt32 // Текстура уменьшенной копии для сетки
}

class AuraPhotosApp: AuraApplication {
    let screenWidth: Float = 1170.0
    let screenHeight: Float = 2532.0
    
    // База данных медиафайлов
    private var photoLibrary: [PhotoAsset] = []
    
    // Состояние интерфейса (.grid — просмотр всех фото, .viewer — фото во весь экран)
    private enum ViewMode {
        case grid
        case viewer
    }
    private var currentMode: ViewMode = .grid
    private var selectedPhotoIndex: Int = 0
    
    override func onLaunch() {
        print("🖼️ AuraPhotos: Индексация медиатеки устройства...")
        refreshLibrary()
    }
    
    /// Сканирование системной папки /user/media/DCIM
    func refreshLibrary() {
        photoLibrary.removeAll()
        
        // Запрашиваем файлы у виртуальной файловой системы (VFS) ядра Rust
        let files = AuraStorage.FileSystem.listDirectory("/user/media/DCIM")
        
        for (index, file) in files.enumerated() {
            // Генерируем или подгружаем из кэша текстуру-миниатюру для каждого кадра
            let thumbId = AuraGraphics.TextureManager.getOrCreateThumbnail(forPath: file.path)
            
            photoLibrary.append(PhotoAsset(
                fileId: UInt64(index),
                localPath: file.path,
                creationTimestamp: file.createdAt,
                thumbnailTextureId: thumbId
            ))
        }
    }
    
    override func onRender() {
        // Чистый белый или черный фон в зависимости от системной темы (выберем черный, как в iOS)
        AuraPainter.drawRect(x: 0, y: 0, width: screenWidth, height: screenHeight, color: .black)
        
        switch currentMode {
        case .grid:
            renderPhotoGrid()
        case .viewer:
            renderFullSizeViewer()
        }
    }
    
    /// 1. Рендеринг сетки фотографий (3 колонки с точными отступами)
    private func renderPhotoGrid() {
        // Верхний заголовок «Библиотека»
        AuraPainter.drawText("Медиатека", x: 40, y: 150, font: .systemCustom(size: 32, weight: .bold), color: .white)
        
        let columns = 3
        let spacing: Float = 4.0 // Минималистичные тонкие швы между фото, как в iOS
        let size = (screenWidth - (spacing * Float(columns - 1))) / Float(columns)
        let startY: Float = 220.0
        
        for (index, asset) in photoLibrary.enumerated() {
            let row = index / columns
            let col = index % columns
            
            let posX = Float(col) * (size + spacing)
            let posY = startY + Float(row) * (size + spacing)
            
            // Если иконка улетает далеко за экран при скролле — не рендерим её (Оптимизация culling)
            if posY > screenHeight || posY < (startY - size) { continue }
            
            // Отрисовываем квадратную миниатюру фото
            AuraPainter.drawTexture(asset.thumbnailTextureId, x: posX, y: posY, width: size, height: size)
        }
        
        // Нижний системный таб-бар галереи (Медиатека / Альбомы / Поиск)
        drawTabBar()
    }
    
    /// 2. Рендеринг просмотра одного фото во весь экран
    private func renderFullSizeViewer() {
        guard selectedPhotoIndex < photoLibrary.count else { return }
        let currentAsset = photoLibrary[selectedPhotoIndex]
        
        // Отрисовка основного снимка на весь экран с сохранением пропорций (Aspect Fit)
        AuraPainter.drawTextureCentered(
            currentAsset.thumbnailTextureId, // В реальном коде тут ID полноразмерной текстуры
            x: screenWidth / 2,
            y: screenHeight / 2,
            maxWidth: screenWidth,
            maxHeight: screenHeight - 200.0
        )
        
        // Верхняя панель: Кнопка «Назад»
        AuraPainter.drawIcon(.arrow_left, x: 50, y: 80, tint: .white)
        
        // Нижняя панель действий (Поделиться, Избранное, Удалить)
        let panelY = screenHeight - 160.0
        AuraPainter.drawLinearGradientBottomToTop(height: 200, startColor: .black.withOpacity(0.6), endColor: .clear)
        
        AuraPainter.drawIcon(.share, x: 80, y: panelY, tint: .white)
        AuraPainter.drawIcon(.heart, x: screenWidth / 2 - 20, y: panelY, tint: .white)
        AuraPainter.drawIcon(.trash, x: screenWidth - 120, y: panelY, tint: .white)
    }
    
    private func drawTabBar() {
        let barHeight: Float = 140.0
        let barY = screenHeight - barHeight
        AuraPainter.drawGlassRect(x: 0, y: barY, width: screenWidth, height: barHeight, cornerRadius: 0, blurRadius: 20, opacity: 0.3)
        
        // Вкладки интерфейса
        AuraPainter.drawIcon(.photos_stack, x: screenWidth / 4 - 20, y: barY + 30, tint: .systemBlue) // Активная вкладка
        AuraPainter.drawText("Фото", x: screenWidth / 4 - 18, y: barY + 95, font: .systemRegular(size: 11), color: .systemBlue)
        
        AuraPainter.drawIcon(.albums, x: (screenWidth / 4) * 3 - 20, y: barY + 30, tint: .gray)
        AuraPainter.drawText("Альбомы", x: (screenWidth / 4) * 3 - 32, y: barY + 95, font: .systemRegular(size: 11), color: .gray)
    }
    
    // ==============================================================================
    // 🕹️ Обработка жестов и кликов в Галерее
    // ==============================================================================
    
    func handleTouch(x: Float, y: Float, event: TouchEvent) {
        guard event == .tap else {
            // Если мы в режиме просмотра фото и пользователь делает горизонтальный свайп
            if currentMode == .viewer, case .drag(let deltaX, _) = event {
                if deltaX < -100.0 && selectedPhotoIndex < photoLibrary.count - 1 {
                    selectedPhotoIndex += 1 // Свайп влево — следующее фото
                    AuraHaptics.vibrate(.lightClick)
                } else if deltaX > 100.0 && selectedPhotoIndex > 0 {
                    selectedPhotoIndex -= 1 // Свайп вправо — предыдущее фото
                    AuraHaptics.vibrate(.lightClick)
                }
            }
            return
        }
        
        switch currentMode {
        case .grid:
            // Вычисляем, на какое фото из сетки нажал пользователь
            let columns = 3
            let spacing: Float = 4.0
            let size = (screenWidth - (spacing * Float(columns - 1))) / Float(columns)
            let startY: Float = 220.0
            
            if y > startY && y < (screenHeight - 140.0) {
                let col = Int(x / (size + spacing))
                let row = Int((y - startY) / (size + spacing))
                let clickedIndex = row * columns + col
                
                if clickedIndex < photoLibrary.count {
                    selectedPhotoIndex = clickedIndex
                    currentMode = .viewer
                    AuraHaptics.vibrate(.lightClick)
                }
            }
            
        case .viewer:
            // Кнопка возврата в сетку (Назад) в левом верхнем углу
            if x > 30 && x < 120 && y > 50 && y < 130 {
                currentMode = .grid
                AuraHaptics.vibrate(.lightClick)
            }
            
            // Кнопка удаления (Мусорка)
            if x > (screenWidth - 150) && y > (screenHeight - 180) {
                AuraStorage.FileSystem.deleteFile(atPath: photoLibrary[selectedPhotoIndex].localPath)
                refreshLibrary() // Пересканируем диск
                currentMode = .grid
                AuraHaptics.vibrate(.notice)
            }
        }
    }
}
