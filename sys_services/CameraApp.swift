import AuraUI
import AuraGraphics
import AuraHardware // Работа с сенсорами камеры и вспышкой

class CameraApp: AuraApplication {
    let screenWidth: Float = 1170.0
    let screenHeight: Float = 2532.0
    
    private var isFrontCamera: Bool = false
    private var selectedMode: String = "ФОТО" // Режимы: ВИДЕО, ФОТО, ПОРТРЕТ
    
    override func onLaunch() {
        print("AuraOS Camera: Запуск сенсоров камеры...")
        AuraHardware.Camera.startCaptureSession(mode: .photo, quality: .ultraHD)
    }
    
    override func onRender() {
        // 1. Отрисовка видоискателя (Прямой потоковый кадр с матрицы камеры на весь экран)
        // Кадр рендерится аппаратно через текстуру в кадровый буфер дисплея
        if let cameraTexture = AuraHardware.Camera.getLiveFrameTexture() {
            AuraPainter.drawTexture(cameraTexture, x: 0, y: 0, width: screenWidth, height: screenHeight)
        }
        
        // 2. Верхняя панель управления (Вспышка, Живые фото, Таймер)
        drawTopBar()
        
        // 3. Нижняя панель управления (Кнопка затвора, галерея, смена камеры)
        drawBottomControlPanel()
    }
    
    private func drawTopBar() {
        AuraPainter.drawLinearGradientTopToBottom(height: 180, startColor: .black.withOpacity(0.4), endColor: .clear)
        
        // Иконка вспышки
        let flashIcon = AuraHardware.Camera.isFlashAuto ? "icon_flash_auto" : "icon_flash_off"
        AuraPainter.drawIcon(named: flashIcon, x: 60, y: 60, tint: .white)
        
        // Экспозиция / Ночной режим
        AuraPainter.drawIcon(.moon, x: screenWidth / 2 - 24, y: 60, tint: .yellow)
    }
    
    private func drawBottomControlPanel() {
        // Полупрозрачная черная подложка управления снизу (как в iOS)
        let panelHeight: Float = 450.0
        let panelY = screenHeight - panelHeight
        AuraPainter.drawRect(x: 0, y: panelY, width: screenWidth, height: panelHeight, color: .black.withOpacity(0.5))
        
        // Выбор режимов (ВИДЕО, ФОТО, ПОРТРЕТ) - центрируем активный режим
        AuraPainter.drawText(selectedMode, x: screenWidth / 2 - 30, y: panelY + 40, font: .systemBold(size: 16), color: .yellow)
        AuraPainter.drawText("ВИДЕО", x: screenWidth / 2 - 180, y: panelY + 40, font: .systemRegular(size: 16), color: .white.withOpacity(0.6))
        AuraPainter.drawText("ПОРТРЕТ", x: screenWidth / 2 + 120, y: panelY + 40, font: .systemRegular(size: 16), color: .white.withOpacity(0.6))
        
        // Большая круглая кнопка затвора (Белое кольцо, белый круг внутри)
        let shutterX = screenWidth / 2
        let shutterY = panelY + 240.0
        AuraPainter.drawCircle(x: shutterX, y: shutterY, radius: 70, color: .white.withOpacity(0.4)) // Внешнее кольцо
        AuraPainter.drawCircle(x: shutterX, y: shutterY, radius: 56, color: .white) // Внутренняя кнопка
        
        // Иконка переключения камер (Фронтальная / Основная)
        let flipX = screenWidth - 150.0
        AuraPainter.drawGlassCircle(x: flipX, y: shutterY, radius: 40, opacity: 0.3)
        AuraPainter.drawIcon(.camera_switch, x: flipX + 20, y: shutterY + 20, tint: .white)
        
        // Квадрат превью галереи (миниатюра последнего снимка)
        let galleryX: Float = 70.0
        AuraPainter.drawRoundedImage(named: "last_photo_thumb", x: galleryX, y: shutterY - 40, width: 80, height: 80, cornerRadius: 16)
    }
    
    /// Обработка тапов внутри приложения Камера
    func handleTouch(x: Float, y: Float, event: TouchEvent) {
        guard event == .tap else { return }
        
        let shutterY = screenHeight - 450.0 + 240.0
        // Проверяем нажатие на кнопку затвора
        let distanceToShutter = sqrt(pow(x - (screenWidth / 2), 2) + pow(y - shutterY, 2))
        if distanceToShutter <= 70 {
            takePhoto()
        }
    }
    
    private func takePhoto() {
        print("AuraOS Camera: Снимок! Сохраняю в буфер...")
        AuraHaptics.vibrate(.heavyClick) // Плотный щелчок вибромотора
        
        // Запускаем аппаратный захват кадра и сохраняем файл в память устройства
        AuraHardware.Camera.captureStillImage { filePath in
            print("Фото сохранено в: \(filePath)")
        }
    }
}
