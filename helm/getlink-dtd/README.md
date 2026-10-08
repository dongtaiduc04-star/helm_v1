# GetLink DTD Helm chart

This chart contains the frontend, API Gateway, Auth Service, Link Service,
optional MySQL StatefulSet and avatar storage. See the repository
[README](../../README.md) for the Azure runtime contract, required external Secret keys
and local lint/template commands.

The base values are generic. The Azure overlay preserves the existing
`getlink-dtd` deployment's image repositories, hostname, Secret references,
Traefik configuration and `local-path` persistence. Its four immutable image
tags initially match the private operational Helm repository. This chart does
not publish images or manage credentials. Keep all passwords in the existing
`getlink-dtd-secrets` Kubernetes Secret, outside Git.

Reusing the existing environment means retaining the release and namespace
`getlink-dtd`, MySQL StatefulSet `getlink-dtd-mysql`, avatar claim
`getlink-dtd-avatars`, and existing database volumes. Do not create a `v1`
namespace, recreate volumes, or run a competing Helm release/Application.
For an intentional external MySQL migration, review that separate data change
before setting `mysql.enabled=false` and changing the two database URLs.

The default topology is for a portfolio/demo. Review storage durability,
database operations and resource/security settings before production use.
