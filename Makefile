
all: build shell

persist:
	mkdir -p persist

build: persist
	docker compose build

shell:
	@if [ "$(LFS_IMG)" = "root" ]; then \
		modprobe nbd max_part=16; \
		qemu-nbd -c /dev/nbd0 ./"$(LFS_IMG)"; \
	fi
	docker compose run \
		-e HOST_USER=$(shell whoami) \
		--rm -it lfs-docker
	@if [ "$(LFS_IMG)" = "root" ]; then \
		rmmod nbd; \
	fi

#fclean:
#	docker compose run -it lfs-docker "make fclean -C ./srcs"
#	rm -rf persist

.PHONY: all build shell

