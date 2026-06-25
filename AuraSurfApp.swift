// Внутри обработки кликов в AuraSurfApp.swift
if targetLink.hasSuffix(".apkg") {
    AuraPackageManager.shared.installApp(fromUrl: targetLink) { success in
        if success {
            // Показываем iOS-уведомление "Приложение установлено"
        }
    }
}
