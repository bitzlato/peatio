RAILS_ENV=
RAILS_MASTER_KEY=
REGISTRY=nexus.lgk.one:5000
IMAGE_NAME=${REGISTRY}/peatio:${RAILS_ENV}

docker-release: docker-build docker-push
docker-build: check-args
	docker build -t ${IMAGE_NAME} --build-arg RAILS_ENV=${RAILS_ENV} .
docker-push: check-args
	docker push ${IMAGE_NAME}
check-args:
ifndef RAILS_ENV
	$(error RAILS_ENV is undefined)
endif
