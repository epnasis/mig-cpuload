# cpuload-mig

Tool for testing Google Cloud autoscaling that generates VM instance CPU load on demand. 
* Builds docker image and poshes it to you Container Registry
* Creates Managed Instance Group (MIG) with autoscaling with instance template that launches docker container 
* Listens on HTTP port for requests to generate/stop 100% CPU load on each instance
* Watch your MIG autoscale based on the load you generate. Change load and see how MIG autoscaler reacts.

## Getting started

1. Open [Cloud Shell](https://cloud.google.com/shell/docs/using-cloud-shell) or your favorite terminal that has gcloud/docker/make installed.

2. Clone this repo

```shell
$ git clone https://github.com/epnasis/mig-cpuload.git
$ cd mig-cpuload/
```

3. Skip this step if using [Cloud Shell](https://cloud.google.com/shell/docs/using-cloud-shell). Otherwise export your Google Cloud project to `GOOGLE_CLOUD_PROJECT`

```shell
$ export GOOGLE_CLOUD_PROJECT=<your_project_here>
```

4. Create new autoscaled MIG for testing:

```shell
make
```

(Optional) Repeat `make` command to create more MIGs. You can adjust CONFIG file if you want to change `MACHINE_TYPE`

5. Connect to your MIG instance using your browser to generate/stop load and test autoscaler features.

6. Once done remove created resources with:

```shell
make clean
```

## Contact

In case of questions contact [pwenda@google.com](mailto:pwenda@google.com)

