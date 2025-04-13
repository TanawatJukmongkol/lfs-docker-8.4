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
		qemu-nbd -d ${LFS_LOOP}; \
		sleep 0.2; \
		rmmod nbd; \
	fi

#fclean:
#	docker compose run -it lfs-docker "make fclean -C ./srcs"
#	rm -rf persist

.PHONY: all build shell

