TARGET = arm64-auraos-none
KERNEL = target/$(TARGET)/release/libaura_core.a
SYS_SERVICES = sys_services/AuraBluetooth.swift sys_services/AirPodsUI.swift

.PHONY: all clean

all: aura_os.img

$(KERNEL): src/main.rs
	cargo build --target $(TARGET) --release

aura_os.img: $(KERNEL) $(SYS_SERVICES)
	# Компилируем Swift-сервисы и линкуем их с микроядром Rust
	swiftc -target arm64-apple-none -O $(SYS_SERVICES) -o build/services.o
	ld.lld build/services.o $(KERNEL) -o build/aura_os.elf
	objcopy -O binary build/aura_os.elf aura_os.img
	@echo "🔥 AuraOS успешно собрана! Образ: aura_os.img"

clean:
	cargo clean
	rm -rf build/* aura_os.img
