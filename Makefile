MACHINE_TYPE:=f1-micro
ZONE:=us-east1-c
CONTAINER_NAME:=cpuload
MIG_TEMPLATE_NAME:=ig-cpuload

CONTAINER_TAG:=gcr.io/$(GOOGLE_CLOUD_PROJECT)/$(CONTAINER_NAME):latest
MIG_NAME:=ig-test-$(shell tr -dc a-z0-9 < /dev/urandom | head -c4)

mig:	mig-template
	gcloud compute instance-groups managed create $(MIG_NAME) \
		--template=$(MIG_TEMPLATE_NAME) \
		--size=1 \
		--zone=$(ZONE)
	gcloud compute instance-groups managed set-autoscaling $(MIG_NAME) \
		--min-num-replicas=1 \
		--max-num-replicas=10 \
		--scale-based-on-cpu \
		--target-cpu-utilization=0.8 \
		--zone=$(ZONE)
	echo $(MIG_NAME) > list-mig

mig-template:
	gcloud compute instance-templates describe ig-cpuload > /dev/null \
	|| gcloud compute instance-templates create-with-container $(MIG_TEMPLATE_NAME) \
		--machine-type=$(MACHINE_TYPE) \
		--container-image=$(CONTAINER_TAG)

docker-build:


docker-push:

