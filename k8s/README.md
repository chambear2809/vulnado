# Kubernetes deployment

These manifests deploy the same topology as `docker-compose.yml`:

- `vulnado-client` serves the static frontend on port 80.
- `vulnado-api` serves the Spring Boot API on port 8080.
- `db` runs Postgres with the demo database.
- `internal-site` is available only inside the cluster.

The database uses ephemeral `emptyDir` storage because Vulnado reseeds Postgres every time the API starts.

## Build and push images

Set the registry and tag, then build and push the three app images:

```sh
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=637423309390
export IMAGE_TAG=k8s-20260628150004
export ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$ECR_REGISTRY"

docker build -t "$ECR_REGISTRY/vulnado-api:$IMAGE_TAG" .
docker build -t "$ECR_REGISTRY/vulnado-client:$IMAGE_TAG" client
docker build -t "$ECR_REGISTRY/vulnado-internal-site:$IMAGE_TAG" internal_site

docker push "$ECR_REGISTRY/vulnado-api:$IMAGE_TAG"
docker push "$ECR_REGISTRY/vulnado-client:$IMAGE_TAG"
docker push "$ECR_REGISTRY/vulnado-internal-site:$IMAGE_TAG"
```

If you use a different registry or tag, update `k8s/kustomization.yaml`.

## Deploy

```sh
kubectl apply -k k8s
kubectl -n vulnado rollout status deploy/db
kubectl -n vulnado rollout status deploy/internal-site
kubectl -n vulnado rollout status deploy/vulnado-api
kubectl -n vulnado rollout status deploy/vulnado-client
```

## Test locally

The frontend JavaScript calls `http://localhost:8080`, so port-forward both services:

```sh
kubectl -n vulnado port-forward svc/vulnado-api 8080:8080
kubectl -n vulnado port-forward svc/vulnado-client 1337:80
```

Open `http://localhost:1337/login.html` and log in with `alice` / `AlicePassword!`.

## Cluster note

This EKS cluster runs Splunk OTel OBI zero-code instrumentation. OBI was injecting into the Vulnado Java process and causing Tomcat to return HTTP 505 responses, so the `vulnado` namespace was added to OBI's `exclude_instrument` list while validating this deployment. If a cluster does not run OBI, no extra step is needed.
