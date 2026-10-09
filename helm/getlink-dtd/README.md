# GetLink DTD Helm chart

The original GetLink chart for frontend, API Gateway, Auth Service, Link Service,
optional MySQL and avatar storage, using only the existing Azure deployment.
Render its base `values.yaml` with `values-azure.yaml`.

Keep release/namespace `getlink-dtd`, MySQL StatefulSet `getlink-dtd-mysql`,
avatar PVC `getlink-dtd-avatars`, `getlink-dtd-secrets`, `ghcr-pull-secret`,
the existing website and `local-path` volumes. Do not create separate v1
resources or commit passwords/tokens.

The app workflow publishes the existing four GHCR images and updates their
full SHA tags in `helm_v1/main`; the one existing Argo Application automatically
deploys the selected Git source. This chart does not publish images or manage
credentials. See the repository [README](../../README.md) for GitHub/Argo
inspection, normal local synchronization and compatible image-tag rollback.
Rollback does not restore database data. Do not run a competing Helm upgrade
or bootstrap; preserve existing data, PVCs and Secrets.
