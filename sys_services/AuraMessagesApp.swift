import AuraUI
import AuraGraphics
import AuraHardware // Доступ к радиомодулю (GSM/LTE модем)

/// Структура отдельного SMS-сообщения
struct SMSMessage {
    let id: UInt64
    let senderNumber: String
    let text: String
    let timestamp: UInt64
    let isIncoming: Bool // true — входящее, false — исходящее (наше)
}

class AuraMessagesApp: AuraApplication {
    let screenWidth: Float = 1170.0
    let screenHeight: Float = 2532.0
    
    // Активный диалог (база данных сообщений)
    private var chatHistory: [SMSMessage] = []
    private var currentInputText: String = ""
    private let targetPhoneNumber = "+7 (999) 123-45-67" // Пример контакта
    
    override func onLaunch() {
        print("AuraOS Messages: Запуск службы сообщений...")
        loadChatHistory()
        
        // Подписываемся на прерывания модема для отслеживания новых ВХОДЯЩИХ SMS
        AuraHardware.Telephony.onSMSReceived { [weak self] incomingSMS in
            let newMsg = SMSMessage(
                id: incomingSMS.id,
                senderNumber: incomingSMS.sender,
                text: incomingSMS.body,
                timestamp: incomingSMS.time,
                isIncoming: true
            )
            self?.chatHistory.append(newMsg)
            AuraHaptics.vibrate(.notice) // Мягкий перестук при получении сообщения
        }
    }
    
    private func loadChatHistory() {
        // Локальная симуляция истории чата (в реальности грузится из зашифрованной базы SQLite AuraOS)
        chatHistory = [
            SMSMessage(id: 1, senderNumber: targetPhoneNumber, text: "Привет! Как там твоя новая AuraOS на GitHub?", timestamp: 1718910000, isIncoming: true),
            SMSMessage(id: 2, senderNumber: "Me", text: "Привет! Всё супер, ядро на Rust работает идеально, UI выдает 144 Гц!", timestamp: 1718910100, isIncoming: false),
            SMSMessage(id: 3, senderNumber: targetPhoneNumber, text: "Круто! Скинь код отправки SMS 🔥", timestamp: 1718910200, isIncoming: true)
        ]
    }
    
    override func onRender() {
        // 1. Рисуем фон приложения (чистый благородный черный, как в iOS Dark Mode)
        AuraPainter.drawRect(x: 0, y: 0, width: screenWidth, height: screenHeight, color: .black)
        
        // 2. Верхняя плашка (Имя контакта и кнопка "Назад")
        drawHeader()
        
        // 3. Отрисовка списка сообщений (лента чата)
        drawMessageBubbles()
        
        // 4. Нижняя панель ввода текста с кнопкой отправки
        drawInputBar()
    }
    
    private func drawHeader() {
        // Небольшое размытие за головой контакта
        AuraPainter.drawGlassRect(x: 0, y: 0, width: screenWidth, height: 240, cornerRadius: 0, blurRadius: 15, opacity: 0.2)
        
        // Аватарка (круг со скруглением)
        AuraPainter.drawCircle(x: screenWidth / 2, y: 110, radius: 45, color: .darkGray)
        AuraPainter.drawText("👨‍💻", x: screenWidth / 2 - 18, y: 125, font: .systemRegular(size: 24), color: .white)
        
        // Имя контакта
        AuraPainter.drawText(targetPhoneNumber, x: screenWidth / 2 - 110, y: 190, font: .systemBold(size: 16), color: .white)
    }
    
    private func drawMessageBubbles() {
        var currentY: Float = 280.0
        let bubbleMaxWidth: Float = 750.0
        
        for msg in chatHistory {
            let textWidth = AuraPainter.calculateTextWidth(msg.text, font: .systemRegular(size: 16))
            let bubbleWidth = min(bubbleMaxWidth, textWidth + 40.0)
            let bubbleHeight: Float = 90.0 // Упрощенно для фиксированных строк
            
            let bubbleX: Float
            let bubbleColor: Color
            
            if msg.isIncoming {
                // Входящие сообщения — серые (слева), как в iOS
                bubbleX = 40.0
                bubbleColor = Color(r: 0.15, g: 0.15, b: 0.15, a: 1.0)
            } else {
                // Исходящие сообщения — фирменный синий/зеленый (справа)
                bubbleX = screenWidth - bubbleWidth - 40.0
                bubbleColor = .systemBlue 
            }
            
            // Рисуем «бабл» сообщения
            AuraPainter.drawRoundedRect(x: bubbleX, y: currentY, width: bubbleWidth, height: bubbleHeight, cornerRadius: 32.0, color: bubbleColor)
            
            // Текст внутри бабла
            AuraPainter.drawText(msg.text, x: bubbleX + 20, y: currentY + 50, font: .systemRegular(size: 16), color: .white)
            
            currentY += bubbleHeight + 20.0 // Сдвиг вниз для следующего сообщения
        }
    }
    
    private func drawInputBar() {
        let barHeight: Float = 160.0
        let barY = screenHeight - barHeight - 40.0 // Отступ под Home Bar
        
        // Поле ввода (Светло-серая рамка со стеклом)
        let inputX: Float = 40.0
        let inputWidth = screenWidth - 180.0
        AuraPainter.drawGlassRect(x: inputX, y: barY, width: inputWidth, height: 90, cornerRadius: 45, blurRadius: 5, opacity: 0.15)
        
        // Текст внутри поля ввода
        let displayText = currentInputText.isEmpty ? "Cообщение iMessage/SMS" : currentInputText
        let textColor: Color = currentInputText.isEmpty ? .gray : .white
        AuraPainter.drawText(displayText, x: inputX + 40, y: barY + 55, font: .systemRegular(size: 16), color: textColor)
        
        // Круглая кнопка отправки (Синий кружок со стрелкой вверх)
        let sendX = screenWidth - 110.0
        let isReadyToSend = !currentInputText.isEmpty
        AuraPainter.drawCircle(x: sendX, y: barY + 45, radius: 35, color: isReadyToSend ? .systemBlue : .darkGray)
        AuraPainter.drawIcon(.arrow_up, x: sendX + 13, y: barY + 28, tint: .white)
    }
    
    /// Физическая отправка SMS через GSM-модем
    func sendSMSNotification(text: String, to number: String) {
        guard !text.isEmpty else { return }
        
        print("AuraOS Hardware: Передача команды AT+CMGS на модем...")
        
        // Вызов низкоуровневой функции ядра Rust, которая дергает драйвер SIM-карты
        let success = AuraHardware.Telephony.sendRawSMS(phoneNumber: number, body: text)
        
        if success {
            let myNewMessage = SMSMessage(
                id: UInt64(AuraTime.getTicks()),
                senderNumber: "Me",
                text: text,
                timestamp: AuraTime.getCurrentTime().timestamp,
                isIncoming: false
            )
            chatHistory.append(myNewMessage)
            currentInputText = "" // Очищаем поле ввода
            AuraHaptics.vibrate(.success) // Приятный щелчок успешной отправки
        } else {
            print("Критическая ошибка: Сбой сети или отсутствует SIM-карта.")
            AuraHaptics.vibrate(.error)
        }
    }
    
    /// Эмуляция тапа по кнопке отправки
    func handleTouch(x: Float, y: Float, event: TouchEvent) {
        guard event == .tap else { return }
        
        // Координаты синей кнопки отправки
        let sendButtonY = screenHeight - 160.0 - 40.0 + 45.0
        let sendButtonX = screenWidth - 110.0
        
        let distance = sqrt(pow(x - sendButtonX, 2) + pow(y - sendButtonY, 2))
        if distance <= 35 {
            // Для теста: если поле пустое, сгенерируем текст, чтобы проверить отправку
            if currentInputText.isEmpty {
                currentInputText = "Отправлено из кода AuraOS на GitHub! 🚀"
            }
            sendSMSNotification(text: currentInputText, to: targetPhoneNumber)
        }
    }
}
