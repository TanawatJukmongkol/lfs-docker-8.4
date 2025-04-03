FROM    debian:10-slim

RUN        apt-get update
RUN        apt-get install -y \
wget \
coreutils \
bash \
make \
bison \
gcc \
g++ \
gawk \
texinfo \
m4 \
patch \
python3 \
qemu \
qemu-utils \
qemu-system-x86 \
libguestfs-tools \
kmod \
cargo \
neovim \
tree

RUN     groupadd lfs
RUN     useradd -s /bin/bash -g lfs -u 1000 -k /dev/null -m lfs

RUN		mkdir -p /persist
RUN		mkdir -p /home/lfs/srcs

# To reset back to host user owned directory.
RUN		chown root -R /home/lfs

RUN     yes lfs | passwd root
RUN     yes lfs | passwd lfs

EXPOSE  22 5900 8006

WORKDIR /home/lfs
ENTRYPOINT [ "/bin/bash", "./srcs/entry.sh" ]

