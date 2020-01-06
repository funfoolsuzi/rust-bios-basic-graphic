.PHONY: build test buildarm testarm

build:
	cargo xbuild --release && \
	cargo objcopy -- --strip-debug -I elf64-x86-64 -O binary --binary-architecture=i386:x86-64 \
		target/x86_64-biosbasicgraphic/release/rust-bios-basic-graphic target/x86_64-biosbasicgraphic/release/rust-bios-basic-graphic.bin

test: build
	qemu-system-x86_64 -drive format=raw,file=target/x86_64-biosbasicgraphic/release/rust-bios-basic-graphic.bin

armbuild:
	cargo xbuild --target arm-biosbasicgraphic.json --release && \
	cargo objcopy -- -I elf32-littlearm -O binary --binary-architecture=arm \
		target/arm-biosbasicgraphic/release/rust-bios-basic-graphic target/arm-biosbasicgraphic/release/rust-bios-basic-graphic.bin

armtest: armbuild
	qemu-system-arm -machine raspi2 -drive format=raw,file=target/arm-biosbasicgraphic/release/rust-bios-basic-graphic.bin