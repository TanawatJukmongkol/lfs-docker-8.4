
all: build shell

persist:
	mkdir -p persist

build: persist
	docker compose build

shell:
	docker compose run --rm -it lfs-docker

#fclean:
#	docker compose run -it lfs-docker "make fclean -C ./srcs"
#	rm -rf persist

.PHONY: all build shell

