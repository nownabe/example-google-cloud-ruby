# Example: Cloud Run with Memorystore for Redis

## Prerequisites

* Cloud SDK (gcloud) 400.0.0
* Terraform 1.2.8
* Docker Engine 20.10.17
* curl

## Steps

### Configure project ID

Create `.envrc` and set your project ID.

```sh
cp .envrc.example .envrc
vi .envrc
source .envrc
```

### Terraform

Authenticate with Google Cloud.

```sh
gcloud auth application-default login
```

Apply terraform to your project.

```sh
cd terraform
terraform init
terraform plan
terraform apply
```

### Deploy

Set up authentication for docker to Artifact Registry.

```sh
gcloud auth configure-docker asia-northeast1-docker.pkg.dev
```

Run the CI/CD script.

```sh
./deploy.sh
```

This script does:

* Build a container image
* Push the container image to the Artifact Registry repository
* Deploy a Cloud Run service (Create a new service or deploy a new revision)

### Test deployed app

Run `test.sh` to test access to each Redis instance with deployed app.

```sh
./test.sh
```

## References

* [Docs overview | hashicorp/google | Terraform Registry](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
* [Enabling in-transit encryption  |  Memorystore for Redis  |  Google Cloud](https://cloud.google.com/memorystore/docs/redis/enabling-in-transit-encryption)
* [Managing Redis AUTH  |  Memorystore for Redis  |  Google Cloud](https://cloud.google.com/memorystore/docs/redis/managing-auth)
* [redis/redis-rb: A Ruby client library for Redis](https://github.com/redis/redis-rb)
