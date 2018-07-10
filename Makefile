all: build up

build:
	docker-compose build

up: 
	docker-compose up -d
	./disable-offload.sh net0-mgmt
	./disable-offload.sh net1-peers

restart: build
	docker-compose stop exabgp
	docker-compose rm -f exabgp
	docker-compose up -d exabgp

ps:
	@docker-compose ps
	@docker logs vmx1 |grep 'password to'
	@docker logs vmx2 |grep 'password to'

down:
	docker-compose down
