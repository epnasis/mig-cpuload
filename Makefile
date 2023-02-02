# Default values
MACHINE_TYPE=e2-micro
ZONE=us-central1-a
NAME=mig-cpuload
MIN_NUM_REPLICAS=1
MAX_NUM_REPLICAS=10
TARGET_CPU_UTILIZATION=0.8
INIT_DELAY_SEC=0

# ---------------------------
include CONFIG

ifeq (${GOOGLE_CLOUD_PROJECT},)
	CHECK_ENV:=$(error "[!] Project not set. Run: export GOOGLE_CLOUD_PROJECT=<your_project_here>")
endif

CONTAINER_TAG:=gcr.io/$(GOOGLE_CLOUD_PROJECT)/$(NAME):latest
MIG_NAME:=$(NAME)-$(shell LC_ALL=C tr -dc 0-9 < /dev/urandom | head -c5)

STATUS:=$(info [*] Initializing...)

MIG_LIST:=$(shell gcloud compute instance-groups managed list --verbosity=error \
	--filter="name ~ ^$(NAME)-[0-9]{5}$$" --format="value(name)")
TEMPLATE_LIST:=$(shell gcloud compute instance-templates list --verbosity=error \
	--filter="name ~ ^$(NAME)-[0-9]{5}$$" --format="value(name)")
HEALTHCHECK_LIST:=$(shell gcloud compute health-checks list --verbosity=error \
	--filter="name ~ ^$(NAME)-[0-9]{5}$$" --format="value(name)")
DOCKER_LIST:=$(shell gcloud container images list --verbosity=none \
	--filter="name:$(NAME)" --format="value(name)")

mig:	.docker mig-template mig-healthcheck
	gcloud compute instance-groups managed create $(MIG_NAME) \
		--template=$(MIG_NAME) \
		--size=1 \
		--health-check=$(MIG_NAME) \
		--zone=$(ZONE)
	gcloud compute instance-groups managed set-autoscaling $(MIG_NAME) \
		--min-num-replicas=$(MIN_NUM_REPLICAS) \
		--max-num-replicas=$(MAX_NUM_REPLICAS) \
		--scale-based-on-cpu \
		--target-cpu-utilization=$(TARGET_CPU_UTILIZATION) \
		--zone=$(ZONE)

mig-template: 
	gcloud compute instance-templates create-with-container $(MIG_NAME) \
		--machine-type=$(MACHINE_TYPE) \
		--container-image=$(CONTAINER_TAG) \
		--container-env INIT_DELAY_SEC=$(INIT_DELAY_SEC) \
		--tags http-server

mig-healthcheck:
	gcloud compute health-checks create http $(MIG_NAME) --port 80 \
		--request-path="/health" \
		--check-interval 10s \
		--healthy-threshold 1 \
		--unhealthy-threshold 3 \
		--timeout 5s

docker: 
	@-rm -f .docker
	@$(MAKE) .docker

.docker: Dockerfile app.py CONFIG
	gcloud services enable containerregistry.googleapis.com
	docker build -t $(CONTAINER_TAG) .
	docker push $(CONTAINER_TAG)
	@touch .docker 

clean: clean-migs clean-templates clean-healthchecks clean-docker

clean-migs:
ifneq ($(MIG_LIST),)
	-gcloud compute instance-groups managed delete -q $(MIG_LIST) --zone=$(ZONE)
endif

clean-templates: 
ifneq ($(TEMPLATE_LIST),)
	-gcloud compute instance-templates delete -q $(TEMPLATE_LIST)
endif

clean-healthchecks:
ifneq ($(HEALTHCHECK_LIST),)
	-gcloud compute health-checks delete -q $(HEALTHCHECK_LIST)
endif

clean-docker:
ifneq ($(DOCKER_LIST),)
	-gcloud container images delete $(DOCKER_LIST) --quiet --force-delete-tags
	-rm .docker
endif

