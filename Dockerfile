FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    debootstrap \
    squashfs-tools \
    xorriso \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY build_mlychos.sh .
RUN chmod +x build_mlychos.sh

CMD ["/bin/bash", "-c", "./build_mlychos.sh && cp mlychos-1.0-amd64.iso /out/"]
