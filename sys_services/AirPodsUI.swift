import AuraUI 

struct AirPodsPopupView: AuraView {
    let device: AppleDevice
    
    var body: some AuraView {
        VStack(spacing: 20) {
            // Элемент интерфейса "Матовое стекло" Aura Glass
            GlassPanel {
                VStack {
                    Text(device.model)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.auraDynamicWhite)
                    
                    // 3D-модель наушников (подгружается из ресурсов ОС)
                    Aura3DModelView(named: "airpods_pro_mesh")
                        .frame(width: 200, height: 150)
                    
                    // Индикаторы батареи
                    HStack(spacing: 40) {
                        BatteryIndicator(label: "L", value: device.batteryLeft)
                        BatteryIndicator(label: "R", value: device.batteryRight)
                    }
                    
                    // Нативная кнопка подключения
                    Button(action: {
                        AuraBluetoothManager.shared.connect(device)
                        AuraHaptics.vibrate(.success) // Отдача моторчика телефона
                    }) {
                        Text("Подключить")
                            .font(.system(size: 16, weight: .semibold))
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                }
                .padding(25)
            }
        }
        .transition(.slideUpFromBottom) // Плавная системная анимация Fluid Motion
    }
}
