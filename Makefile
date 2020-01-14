# Default values
MACHINE_TYPE=f1-micro
ZONE=us-east1-c
CONTAINER_NAME=mig-cpuload
MIN_NUM_REPLICAS=1
MAX_NUM_REPLICAS=10
TARGET_CPU_UTILIZATION=0.8

# ---------------------------
include CONFIG

ifeq (${GOOGLE_CLOUD_PROJECT},)
	CHECK_ENV:=$(error "[!] Project not set. Run: export GOOGLE_CLOUD_PROJECT=<your_project_here>")
endif

CONTAINER_TAG:=gcr.io/$(GOOGLE_CLOUD_PROJECT)/$(CONTAINER_NAME):latest
MIG_NAME:=$(CONTAINER_NAME)-$(shell LC_ALL=C tr -dc 0-9 < /dev/urandom | head -c5)

STATUS:=$(info [*] Initializing...)

MIG_LIST:=$(shell gcloud compute instance-groups managed list \
	--filter="name ~ ^$(CONTAINER_NAME)-[0-9]{5}$$" --format="value(name)")
TEMPLATE_LIST:=$(shell gcloud compute instance-templates list \
	--filter="name ~ ^$(CONTAINER_NAME)-[0-9]{5}$$" --format="value(name)")
DOCKER_LIST:=$(shell gcloud container images list \
	--filter="name:$(CONTAINER_NAME)" --format="value(name)")

mig:	.docker mig-template 
	gcloud compute instance-groups managed create $(MIG_NAME) \
		--template=$(MIG_NAME) \
		--size=1 \
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
		--tags http-server

docker: 
	@-rm -f .docker
	@$(MAKE) .docker

.docker: Dockerfile app.py CONFIG
	docker build -t $(CONTAINER_TAG) .
	docker push $(CONTAINER_TAG)
	@touch .docker 

clean: clean-migs clean-templates clean-docker

clean-migs:
ifneq ($(MIG_LIST),)
	-gcloud compute instance-groups managed delete -q $(MIG_LIST) --zone=$(ZONE)
endif

clean-templates: 
ifneq ($(TEMPLATE_LIST),)
	-gcloud compute instance-templates delete -q $(TEMPLATE_LIST)
endif

clean-docker:
ifneq ($(DOCKER_LIST),)
	-gcloud container images delete $(DOCKER_LIST) --quiet --force-delete-tags
	-rm .docker
endif

