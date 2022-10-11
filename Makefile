DOCKER_NAME := $(shell bash -c 'echo $$RANDOM')
DOCKER_ID := $(shell docker ps -aqf "name=$(DOCKER_NAME)")

build:
	docker build . -f Dockerfile --platform=linux/amd64 -t msyksphinz/buildroot

run: build
	echo "Docker Name is " $(DOCKER_NAME)
	docker run --rm --name=$(DOCKER_NAME) -itd msyksphinz/buildroot /bin/sh
	$(MAKE) copy DOCKER_NAME=$(DOCKER_NAME)

copy:
	docker cp $(DOCKER_ID):/work-buildroot/buildroot/output_qemu   output_qemu
	docker cp $(DOCKER_ID):/work-buildroot/buildroot/output_spike  output_spike
	docker cp $(DOCKER_ID):/work-buildroot/buildroot/output_hifive output_hifive
	docker kill $(DOCKER_NAME)

run-qemu:
	./qemu/riscv64-softmmu/qemu-system-riscv64 \
		-d in_asm -D trace.log \
		-bios ./output_qemu/images/fw_jump.elf \
		-nographic -machine virt -kernel ./output_qemu/images/Image \
		-append "root=/dev/vda ro console=ttyS0" \
		-drive file=./output_qemu/images/rootfs.ext2,format=raw,id=hd0 -device virtio-blk-device,drive=hd0 \
		-netdev user,id=net0 -device virtio-net-device,netdev=net0

run-qemu-hifive:
	./qemu/riscv64-softmmu/qemu-system-riscv64 \
		-d in_asm -D hifive_trace.log \
		-bios ./output_hifive/images/fw_jump.elf \
		-nographic -machine virt -kernel ./output_hifive/images/Image \
		-append "root=/dev/vda ro console=ttyS0" \
		-drive file=./output_hifive/images/rootfs.ext2,format=raw,id=hd0 -device virtio-blk-device,drive=hd0 \
		-netdev user,id=net0 -device virtio-net-device,netdev=net0

run-spike-hifive:
	spike --isa=rv64imac --dtb ../../../dts/rv64imc.dtb --kernel ./output_hifive/images/Image ./output_hifive/images/fw_jump.elf


clean:
	rm -rf output_hifive output_qemu output_spike
