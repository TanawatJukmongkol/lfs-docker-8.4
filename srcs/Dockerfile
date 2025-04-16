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
libguestfs-tools \
sudo

RUN     groupadd lfs
RUN     useradd -s /bin/bash -g lfs -k /dev/null -m lfs

RUN		adduser lfs sudo
RUN		echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN		mkdir -p /persist
RUN		mkdir -p /home/lfs/srcs

RUN     yes lfs | passwd root
RUN     yes lfs | passwd lfs

RUN     echo "# Dockerfile generated config"     > /etc/fuse.conf
RUN     echo "#mount_max = 1000"                >> /etc/fuse.conf
RUN     echo "user_allow_other"                 >> /etc/fuse.conf

EXPOSE  22 5900 8006

WORKDIR /home/lfs
ENTRYPOINT [ "/bin/bash", "./srcs/entry.sh" ]

