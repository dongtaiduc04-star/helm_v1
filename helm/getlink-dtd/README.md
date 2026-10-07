# GetLink DTD Helm chart

This chart contains the frontend, API Gateway, Auth Service, Link Service,
optional MySQL StatefulSet and avatar storage. See the repository
[README](../../README.md) for example overlays, required external Secret keys
and local lint/template commands.

The base and Azure values are sanitized examples. Replace image repositories,
tags and domains before any separately
authorized deployment. This repository does not publish images or manage
credentials. For external MySQL, set `mysql.enabled=false` and configure the
two database URLs; keep real passwords in `existingSecret`, outside Git.

The default topology is for a portfolio/demo. Review storage durability,
database operations and resource/security settings before production use.
