// Внутри класса AuraShell добавим экземпляр шторки
private var controlCenter = ControlCenter()

func handleGlobalTouch(x: Float, y: Float, eventType: TouchEvent) {
    switch eventType {
    case .slideDownFromTopRight(let dragDelta):
        // Если пользователь тянет сверху справа, плавно увеличиваем раскрытие шторки
        controlCenter.currentExpansion = dragDelta / 500.0 // 500px — полный ход
    default:
        break
    }
}
