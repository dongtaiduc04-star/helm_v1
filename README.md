# helm_v1 — GetLink Azure Helm chart

The public Azure-only copy of the original GetLink chart. It reuses the existing
Azure environment, website and data. The original private repositories remain
unchanged. Companion repositories: [app_v1](https://github.com/dongtaiduc04-star/app_v1)
and [infra_v1](https://github.com/dongtaiduc04-star/infra_v1).

## Workflow

The configured owner push to `app_v1/main` publishes the same four GHCR images and updates
the image tags in `helm_v1/main`. The one existing Argo Application
`argocd/getlink-dtd` watches this repository and automatically synchronizes the
existing application. No additional Helm deployment workflow is required.
The owner confirmed the existing site worked after activation on 2026-10-08.
In `app_v1` repository settings, `HELM_REPO_NAME` must be `helm_v1`; keep the
existing owner-approved `ENABLE_AZURE_DELIVERY=true` and delivery access. This
does not change the private app/Helm repositories or grant readers write access.

In GitHub, open `app_v1` → **Actions** and inspect the release workflow's jobs:

- **Build, Test, Checkstyle & SonarQube (PRs)**
- **Build Docker images and push to GHCR (push to main)**
- **Update GetLink Helm values**

Then open `helm_v1` → **Code** → `helm/getlink-dtd/values-azure.yaml` and check
the four image tags, or open the existing website. If you already have access
to the Argo UI, the existing Application should show `Synced` and `Healthy`.
Do not expose a new Argo endpoint or rerun bootstrap for a routine release.

## Existing Azure configuration

Use chart `helm/getlink-dtd`, its base `values.yaml`, and `values-azure.yaml`.

| Setting | Existing value |
| --- | --- |
| Application, release, namespace and resource prefix | `getlink-dtd` |
| Credential Secret / registry Secret | `getlink-dtd-secrets` / `ghcr-pull-secret` |
| Images | `ghcr.io/dongtaiduc04-star/getlink-dtd-{frontend,api-gateway,auth-service,link-service}` |
| Website | `https://getlink-azure.dongtaiduc.me` |
| MySQL and avatar storage | `local-path`, existing volumes |

Keep these identities, the existing database, PVCs, Secrets and Cloudflare
Tunnel. Argo selects one Helm repository at a time; do not create a second
Application, namespace or environment. The old app workflow still updates its
own private Helm repository. Avoid simultaneous releases because both app
workflows share the image packages, `latest` tags and SonarQube project.

All four deployed image tags use the same full application commit SHA, not
`latest`. Read the current remote values; an older local checkout may be stale.
Never commit credentials. The existing Secret keys are `mysql-root-password`,
`auth-db-password`, `link-db-password` and `jwt-secret`.

## Manual changes and rollback

The application workflow makes remote Helm commits. Before editing a clean
local `helm_v1` checkout, run `git pull --ff-only origin main`. If local changes
exist or fast-forwarding fails, stop and review; do not reset or force-push.
Use normal reviewed commits/merges. Do not run a competing Helm install/upgrade,
Terraform apply, or initial-publication script for application updates.

For an owner-reviewed rollback, coordinate pending releases, choose an available
known-good SHA compatible with the current database, and normally revert/commit
only the four image tags in the selected Helm repository. Keep data, PVCs,
Secrets and routes unchanged. Argo applies the Git change automatically.
An Argo UI-only rollback or `kubectl rollout undo` does not change desired Git
state and may be reversed by reconciliation. Image rollback does not restore
data or reverse a database migration.

Only the owner has intended human write access; the authorized app workflow
also updates image values. Public readers receive no write token. See
[SECURITY.md](SECURITY.md) and [CONTRIBUTING.md](CONTRIBUTING.md). No new
open-source license has been granted; retain third-party notices.
