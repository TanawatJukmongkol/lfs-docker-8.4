FROM    debian:10-slim

RUN        apt-get update
RUN        apt-get install -y \
wget \
coreutils \
automake \
bash \
make \
bison \
gcc \
g++ \
gawk \
texinfo \
m4 \
libmpc-dev \
patch \
python3 \
kmod \
flex \
tree \
libguestfs-tools

# qemu \
# qemu-utils \
# nbd-client \

RUN     groupadd lfs
RUN     useradd -s /bin/bash -g lfs -u 1000 -k /dev/null -m lfs

RUN		mkdir -p /persist
RUN		mkdir -p /home/lfs/srcs

# To reset back to host user owned directory.
RUN		chown root -R /home/lfs

RUN     yes lfs | passwd root
RUN     yes lfs | passwd lfs

RUN     echo "# Dockerfile generated config"     > /etc/fuse.conf
RUN     echo "#mount_max = 1000"                >> /etc/fuse.conf
RUN     echo "user_allow_other"                 >> /etc/fuse.conf

EXPOSE  22 5900 8006

WORKDIR /home/lfs
ENTRYPOINT [ "/bin/bash", "./srcs/entry.sh" ]

