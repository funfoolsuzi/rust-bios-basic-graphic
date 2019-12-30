.PHONY: build test

build:
	cargo xbuild --release && \
	cargo objcopy -- --strip-debug -I elf64-x86-64 -O binary --binary-architecture=i386:x86-64 \
		target/x86_64-biosbasicgraphic/release/rust-bios-basic-graphic target/x86_64-biosbasicgraphic/release/rust-bios-basic-graphic.bin

test: build
	qemu-system-x86_64 -drive format=raw,file=target/x86_64-biosbasicgraphic/release/rust-bios-basic-graphic.bin