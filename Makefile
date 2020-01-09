# Default values
MACHINE_TYPE=f1-micro
ZONE=us-east1-c
CONTAINER_NAME=mig-cpuload

# ---------------------------
include CONFIG
CONTAINER_TAG:=gcr.io/$(GOOGLE_CLOUD_PROJECT)/$(CONTAINER_NAME):latest
MIG_NAME:=$(CONTAINER_NAME)-$(shell tr -dc 0-9 < /dev/urandom | head -c5)
MIG_NAMES:=$(shell gcloud compute instance-groups managed list --filter="name ~ ^$(CONTAINER_NAME)-[0-9]{5}" --format="value(name)")
TEMPLATE_NAMES:=$(shell gcloud compute instance-templates list --filter="name ~ ^$(CONTAINER_NAME)-[0-9]{5}" --format="value(name)")

mig:	.docker mig-template 
	gcloud compute instance-groups managed create $(MIG_NAME) \
		--template=$(MIG_NAME) \
		--size=1 \
		--zone=$(ZONE)
	gcloud compute instance-groups managed set-autoscaling $(MIG_NAME) \
		--min-num-replicas=1 \
		--max-num-replicas=10 \
		--scale-based-on-cpu \
		--target-cpu-utilization=0.8 \
		--zone=$(ZONE)

mig-template: 
	gcloud compute instance-templates create-with-container $(MIG_NAME) \
		--machine-type=$(MACHINE_TYPE) \
		--container-image=$(CONTAINER_TAG) \
		--tags http-server

.docker: Dockerfile app.py CONFIG
	docker build -t $(CONTAINER_TAG) .
	docker push $(CONTAINER_TAG)
	@touch .docker 

clean: clean-migs clean-templates

clean-migs:
ifneq ($(MIG_NAMES),)
	gcloud compute instance-groups managed delete -q $(MIG_NAMES) --zone=$(ZONE)
endif

clean-templates: 
ifneq ($(TEMPLATE_NAMES),)
	gcloud compute instance-templates delete -q $(TEMPLATE_NAMES) 
endif



