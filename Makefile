# ==============================================================================
# 🌌 AuraOS Полный Системный Сборщик (Makefile) — Исправленная Версия
# ==============================================================================

TARGET       := arm64-auraos-none
RUST_TARGET  := target/$(TARGET)/release/libaura_core.a

LD           := ld.lld
OBJCOPY      := objcopy

BUILD_DIR    := build
SRC_DIR      := src
SYS_DIR      := sys_services

# Строго те файлы, которые реально существуют в твоем репозитории на скриншоте!
SWIFT_SERVICES := \
    $(SYS_DIR)/AuraBluetooth.swift \
    $(SYS_DIR)/AirPodsUI.swift \
    $(SYS_DIR)/AuraShellr.swift \
    $(SYS_DIR)/CameraApp.swift \
    $(SYS_DIR)/AppSwitcher.swift \
    $(SYS_DIR)/AuraTaskManager.swift \
    $(SYS_DIR)/AuraMessagesApp.swift \
    $(SYS_DIR)/AuraSettingsApp.swift \
    $(SYS_DIR)/AuraPhoneApp.swift \
    $(SYS_DIR)/AuraNetworkStack.swift \
    $(SYS_DIR)/AuraSurfApp.swift \
    $(SYS_DIR)/AuraPhotosApp.swift \
    $(SYS_DIR)/AuraAppInstaller.swift

SWIFT_OBJS     := $(BUILD_DIR)/services.o
OUTPUT_IMG     := aura_os.img
OUTPUT_ELF     := $(BUILD_DIR)/aura_os.elf

SWIFT_FLAGS    := -target arm64-apple-none -O -parse-as-library -enable-experimental-feature EmbeddedSwift

.PHONY: all clean directories kernel swift link info

all: info directories kernel swift link
	@echo "=============================================================================="
	@echo "🔥 [УСПЕХ] AuraOS успешно собрана!"
	@echo "=============================================================================="

info:
	@echo "🌌 Сборка AuraOS..."
	@echo "------------------------------------------------------------------------------"

directories:
	@mkdir -p $(BUILD_DIR)

kernel:
	@echo "📦 [1/3] Компиляция микроядра AuraCore (Rust)..."
	@cargo build --target $(TARGET) --release --quiet

swift:
	@echo "🎨 [2/3] Компиляция графической оболочки и приложений (Swift)..."
	@swiftc $(SWIFT_FLAGS) $(SWIFT_SERVICES) -o $(SWIFT_OBJS)

link: $(SWIFT_OBJS)
	@echo "🔗 [3/3] Линковка компонентов и создание системного образа..."
	@$(LD) $(SWIFT_OBJS) $(RUST_TARGET) -o $(OUTPUT_ELF)
	@$(OBJCOPY) -O binary $(OUTPUT_ELF) $(OUTPUT_IMG)

clean:
	@echo "🧹 Очистка..."
	@cargo clean
	@rm -rf $(BUILD_DIR)
	@rm -f $(OUTPUT_IMG)
