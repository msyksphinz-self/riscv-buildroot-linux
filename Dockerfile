FROM ubuntu:22.04

# -----------------------------
# Ubuntu Package Update
# -----------------------------
RUN apt update

RUN apt install -y git python3 make autoconf g++ device-tree-compiler pkg-config

RUN apt install -y libglib2.0-dev
RUN apt install -y libpixman-1-dev
RUN apt install -y ninja-build

WORKDIR /work-buildroot/

# -------------------
# Build QEMU Package
# -------------------

WORKDIR /work-buildroot/
RUN git clone https://github.com/qemu/qemu
WORKDIR /work-buildroot/qemu
RUN ./configure --target-list=riscv64-softmmu
RUN make -j $(nproc)
RUN make install

# ----------------
# Buildroot Build
# ----------------
WORKDIR /work-buildroot/
RUN git clone https://github.com/buildroot/buildroot.git
WORKDIR /work-buildroot/buildroot/
RUN make qemu_riscv64_virt_defconfig
RUN apt install -y file wget cpio unzip rsync bc
RUN make -j 10
RUN mv output output_qemu
# RUN qemu-system-riscv64 \
#    -M virt -nographic \
#    -bios output/images/fw_jump.elf \
#    -kernel output/images/Image \
#    -append "root=/dev/vda ro" \
#    -drive file=output/images/rootfs.ext2,format=raw,id=hd0 \
#    -device virtio-blk-device,drive=hd0 \
#    -netdev user,id=net0 -device virtio-net-device,netdev=net0

RUN make clean
RUN make spike_riscv64_defconfig
RUN make -j 10
RUN mv output output_spike

# ====================================
# Make HiFive Unleashed Configuration
# ====================================
RUN make clean
RUN make hifive_unleashed_defconfig
RUN make -j 10
RUN mv output output_hifive
