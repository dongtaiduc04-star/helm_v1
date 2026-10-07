# helm_v1 — GetLink DTD Azure Helm examples

A source-only portfolio copy of the GetLink application chart. This repository
is separate from the private operational GitOps repository. Its CI only lints
and renders templates; it never applies them to a cluster.

- [app_v1](https://github.com/dongtaiduc04-star/app_v1): application source.
- [infra_v1](https://github.com/dongtaiduc04-star/infra_v1): Azure infrastructure examples.

## Configuration

The chart is in `helm/getlink-dtd`. The base and Azure/k3s values are examples,
not a ready-to-run deployment. Registry names, image tags and hostnames must
be replaced with ones you own. This public app copy does not publish images.

Create `existingSecret` separately through your secret management system.
Its keys are `mysql-root-password`, `auth-db-password`, `link-db-password`
and `jwt-secret` (at least 32 random bytes). Never put their values in Git.
An `imagePullSecrets` name is a reference, not the registry credential itself.

Azure examples use Traefik and `local-path` storage; TLS terminates at a
separately configured Cloudflare Tunnel. The bundled MySQL and single-replica avatar PVC are
portfolio/demo tradeoffs, not a highly available production topology.

## Local checks and CI

CI uses Helm 4.3.0, read-only repository permissions, and GitHub-hosted runners.
It runs lint and offline template rendering for the base and Azure values.
These checks do not establish that a real cluster can run the application.

```sh
helm lint helm/getlink-dtd
helm template getlink-dtd helm/getlink-dtd
helm lint helm/getlink-dtd -f helm/getlink-dtd/values-azure.yaml
helm template getlink-dtd helm/getlink-dtd -f helm/getlink-dtd/values-azure.yaml
```

Do not run `helm install` or `helm upgrade` against an existing environment
just to inspect this publication.

## Access and licensing

Only the owner is intended to have write/merge access. See
[CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md).
No new open-source license is granted by this publication; existing third-party
licenses and notices still apply. The previous repository history, including
legacy Vprofile examples, is not included.
