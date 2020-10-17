
.PHONY: build
build:
	docker build -t harbinger-dev -f Dockerfile.dev .

.PHONY: watch
watch-frontend:
	docker run --rm -it -v $$(pwd):/app -w /app harbinger-dev bash -c 'npx vue-cli-service build --watch'

.PHONY: server
server:
	docker run --rm -it -p 4000:4000 -v $$(pwd):/app -w /app harbinger-dev bash

.PHONY: shell
shell:
	docker run --rm -it -p 4000:4000 -v $$(pwd):/app -w /app harbinger-dev bash
