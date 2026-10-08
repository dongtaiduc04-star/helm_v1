# helm_v1 — GetLink DTD Azure GitOps chart

A public version of the GetLink application chart, prepared to reuse the
existing Azure environment. It does not create a second application or a new
namespace. Its CI only lints, renders and checks the deployment contract;
it never applies resources to a cluster.

- [app_v1](https://github.com/dongtaiduc04-star/app_v1): application source.
- [infra_v1](https://github.com/dongtaiduc04-star/infra_v1): Azure infrastructure and operator procedures.

## Configuration

The chart is in `helm/getlink-dtd`. `values.yaml` remains a generic base;
`values-azure.yaml` records the existing, non-secret Azure deployment metadata:

| Setting | Existing Azure value |
| --- | --- |
| Helm release, resource prefix and namespace | `getlink-dtd` |
| App and database credential Secret | `getlink-dtd-secrets` |
| Private GHCR pull Secret | `ghcr-pull-secret` |
| Images | `ghcr.io/dongtaiduc04-star/getlink-dtd-{frontend,api-gateway,auth-service,link-service}` |
| Application URL | `https://getlink-azure.dongtaiduc.me` |
| MySQL and avatar storage class | `local-path` |

All four image tags are the same full source commit SHA, not `latest`. The
initial operational overlay retains the SHA recorded by the private Helm
repository; it is not a claim that those images or a running cluster have
been inspected. Only an owner-approved application release may update tags.
The intended application release workflow uses these existing GHCR packages,
not separate `v1` packages.

Keep the existing `existingSecret` in the existing namespace.
Its keys are `mysql-root-password`, `auth-db-password`, `link-db-password`
and `jwt-secret` (at least 32 random bytes). Never put their values in Git.
An `imagePullSecrets` name is a reference, not the registry credential itself.

Azure uses Traefik and `local-path` storage; TLS terminates at the existing
separately configured Cloudflare Tunnel. The bundled MySQL and single-replica avatar PVC are
portfolio/demo tradeoffs, not a highly available production topology.

## One GitOps controller, one selected source

The existing Argo CD Application is `argocd/getlink-dtd`; its destination is
the existing `getlink-dtd` namespace. It must select exactly one source:
the private `dongtaiduc04-star/helm` repository or this public `helm_v1`
repository. Both use chart path `helm/getlink-dtd`, release `getlink-dtd`, and
value files `values.yaml` then `values-azure.yaml`. Changes to the inactive
repository must not be deployed by a second Application.

Preparing or publishing these files does not select this repository in Argo
CD. The owner must separately approve switching the existing Application.
Before that switch, allow the two exact repository URLs in its existing
AppProject, inspect the live source/revision and rendered diff, and confirm
that the public values match the actual namespace, image tags and storage.
The intended steady state is automatic sync from the selected source only.
Never create a second Application for the same resources or copy/delete the
namespace, MySQL database, PVCs, Secrets or Cloudflare Tunnel.

Each application workflow updates its own fixed Helm repository: the private
`app` workflow updates `helm`, and `app_v1` updates `helm_v1`, even when its
repository is inactive in Argo CD. Updating the inactive Helm repository does
not deploy it; the single existing Application selects the deployed source.
Coordinate releases to avoid concurrent writes to the shared GHCR `latest`
tags or simultaneous analysis of the same SonarQube project. Deployment values
still use full immutable SHA tags. Rollback is an owner-reviewed source/tag
change on the same existing Application, not deleting and reinstalling the
chart. See the operator procedures in
[infra_v1](https://github.com/dongtaiduc04-star/infra_v1).

## Local checks and CI

CI uses Helm 4.3.0, read-only repository permissions, and GitHub-hosted runners.
It runs lint and offline template rendering for the base and Azure values,
then checks the existing Azure resource/image/Secret/storage contract.
These checks do not establish that a real cluster can run the application.

```sh
helm lint helm/getlink-dtd
helm template getlink-dtd helm/getlink-dtd
helm lint helm/getlink-dtd -f helm/getlink-dtd/values-azure.yaml
helm template getlink-dtd helm/getlink-dtd -f helm/getlink-dtd/values-azure.yaml
pwsh -File scripts/Test-AzureContract.ps1
```

The contract test does not contact Kubernetes, GHCR, GitHub or Azure. A green
CI run does not establish that image access, Secrets, the database, DNS or the
running application work. Do not run `helm install` or `helm upgrade` against
the existing environment just to inspect this publication; Argo CD owns it.

## Access and licensing

Only the owner is intended to have write/merge access. See
[CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md).
No new open-source license is granted by this publication; existing third-party
licenses and notices still apply. The previous repository history, including
legacy Vprofile examples, is not included.
