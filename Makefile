# ==============================================================================
# 🌌 AuraOS Полный Системный Сборщик (Makefile)
# ==============================================================================

# Настройки архитектуры процессора (Мобильный чипсет ARM64)
TARGET       := arm64-auraos-none
RUST_TARGET  := target/$(TARGET)/release/libaura_core.a

# Инструменты сборки (Линковщик LLVM и утилита копирования бинарников)
LD           := ld.lld
OBJCOPY      := objcopy

# Каталоги проекта
BUILD_DIR    := build
SRC_DIR      := src
SYS_DIR      := sys_services

# Полный список системных модулей и приложений на Swift
SWIFT_SERVICES := \
    $(SYS_DIR)/AuraBluetooth.swift \
    $(SYS_DIR)/AirPodsUI.swift \
    $(SYS_DIR)/AuraShell.swift \
    $(SYS_DIR)/HomeScreen.swift \
    $(SYS_DIR)/LockScreen.swift \
    $(SYS_DIR)/ControlCenter.swift \
    $(SYS_DIR)/CameraApp.swift \
    $(SYS_DIR)/AuraTaskManager.swift \
    $(SYS_DIR)/AuraMessagesApp.swift

# Объектные файлы, которые получатся после компиляции Swift
SWIFT_OBJS     := $(BUILD_DIR)/services.o

# Финальный файл прошивки ОС
OUTPUT_IMG     := aura_os.img
OUTPUT_ELF     := $(BUILD_DIR)/aura_os.elf

# Флаги компиляции Swift для работы в режиме "голого железа" (без ОС Apple)
SWIFT_FLAGS    := -target arm64-apple-none -O -parse-as-library -enable-experimental-feature EmbeddedSwift

# ==============================================================================
# 🚀 Основные сценарии (Правила) Сборки
# ==============================================================================

.PHONY: all clean directories kernel swift link info

# По умолчанию запускается полная сборка системы
all: info directories kernel swift link
	@echo "=============================================================================="
	@echo "🔥 [УСПЕХ] AuraOS успешно собрана и упакована!"
	@echo "📱 Образ для прошивки телефона: ./$(OUTPUT_IMG)"
	@echo "=============================================================================="

# Вывод информации о текущей сборке
info:
	@echo "🌌 Сборка AuraOS [Базовая платформа: Собственная, Визуал: iOS Style]"
	@echo "📦 Целевая архитектура: $(TARGET)"
	@echo "🛠 Инструменты: Swiftc (Embedded) + Cargo (Rust)"
	@echo "------------------------------------------------------------------------------"

# Автоматическое создание папки для временных файлов компиляции
directories:
	@mkdir -p $(BUILD_DIR)

# 1. Компиляция микроядра AuraCore на Rust
kernel: $(SRC_DIR)/main.rs
	@echo "📦 [1/3] Компиляция микроядра AuraCore (Rust)..."
	@cargo build --target $(TARGET) --release --quiet

# 2. Компиляция всех интерфейсов и приложений на Swift
swift: $(SWIFT_SERVICES)
	@echo "🎨 [2/3] Компиляция графической оболочки и приложений (Swift)..."
	@swiftc $(SWIFT_FLAGS) $(SWIFT_SERVICES) -o $(SWIFT_OBJS)

# 3. Линковка модулей и создание финального бинарного образа ОС
link: $(RUST_TARGET) $(SWIFT_OBJS)
	@echo "🔗 [3/3] Линковка компонентов и создание системного образа..."
	# Сшиваем код Swift и Rust в один исполняемый ELF-файл
	@$(LD) $(SWIFT_OBJS) $(RUST_TARGET) -o $(OUTPUT_ELF)
	# Очищаем от отладочной информации и делаем чистый бинарник для процессора
	@$(OBJCOPY) -O binary $(OUTPUT_ELF) $(OUTPUT_IMG)

# Очистка проекта от временных файлов сборки перед чистым коммитом
clean:
	@echo "🧹 Очистка временных файлов и сборщиков..."
	@cargo clean
	@rm -rf $(BUILD_DIR)
	@rm -f $(OUTPUT_IMG)
	@echo "✨ Репозиторий очищен!"
