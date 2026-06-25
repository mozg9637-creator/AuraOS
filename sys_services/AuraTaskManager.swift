// Внутри AuraShell.swift
private var appSwitcher = AppSwitcher()

func triggerAppSwitcher() {
    // Подгружаем актуальные процессы перед открытием
    appSwitcher.loadActiveProcesses() 
    AuraShell.shared.changeState(to: .appSwitcherMode)
}
