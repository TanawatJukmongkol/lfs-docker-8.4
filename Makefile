include .config
export

all: build shell

persist:
	mkdir -p persist

build: persist
	docker compose build

shell:
	@- if [ "$(shell whoami)" = "root" ]; then \
		echo "Notice: Enter as LFS docker as superuser mode."; \
		modprobe nbd max_part=8; \
		sleep 0.5; \
		source ./srcs/scripts/init_img_root.sh; \
	fi
	docker compose run \
		-e HOST_USER=$(shell whoami) \
		--rm -it lfs-docker
	@- if [ "$(shell whoami)" = "root" ]; then \
		sleep 0.2; \
		rmmod nbd; \
	fi

vm:
	qemu-system-x86_64 \
	-enable-kvm \
	-machine \
	type=pc,accel=kvm \
	-cpu host \
	-smp sockets=1,cores=4,threads=4 \
	-k de \
	-usb \
	-m 2048 \
	-net nic \
	-net user,id=vmnic,hostfwd=tcp::2222-:22 \
	-bios /nix/store/0wbr8qhmbddqd419hfapj3pkzn71xrq1-OVMF-202402-fd/FV/OVMF.fd \
	-display default,gl=on,show-cursor=on \
	-device virtio-gpu \
	-device usb-mouse \
	-device usb-tablet \
	-hda ./persist/home/lfs/build/dist/lfs.qcow2 \
	-display default,gl=on,show-cursor=on \
	-boot menu=on \
	-cdrom ~/Downloads/archlinux-x86_64.iso \

# -vga none \

#fclean:
#	docker compose run -it lfs-docker "make fclean -C ./srcs"
#	rm -rf persist

.PHONY: all build shell

