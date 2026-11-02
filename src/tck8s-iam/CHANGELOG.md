# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.8] - 2026-10-19
### Added
- Improved `iiqdeptools.py` with real-time output streaming via `subprocess.Popen` and 'BUILD FAILED' detection in stdout.
- Added support for dynamic PostgreSQL configuration via `PG_HOST` and `PG_PORT` environment variables.
- Implemented Traefik Ingress for external service exposure, replacing the restricted `NodePort` approach.
- Added a Kubernetes Service for the database to enable reliable internal CoreDNS resolution.
- Enhanced `iiqdeptools.py` to use Ant property injection (`-D` arguments) to solve read-only filesystem issues in `SSB_HOME`.

### Changed
- Refactored configuration management to write properties to `CATALINA_BASE` instead of `SSB_HOME` to resolve permission errors.
- Updated `build.sh` to support loading properties from the `CATALINA_BASE` directory.
- Updated Kubernetes networking architecture to use Ingress for external traffic.

## [1.0.7] - 2026-10-16
### Added
- Implemented `initContainer` for `conf` volume to seed existing configuration files from the container image, preventing them from being hidden by dynamic volume mounts.

### Changed
- Transitioned from manual `hostPath` PersistentVolumes to dynamic provisioning using the `local-path-provisioner` (via `local-path` StorageClass).
- Updated `values.yaml` to use the `local-path` StorageClass for all dynamic volumes.
- Removed reliance on `pvs.yaml` and manual PV management.

## [1.0.6] - 2026-10-08
### Added
- Support for `standard` StorageClass and manual `PersistentVolume` (PV) definitions for local development.
- Included `db-data` in the global `volumes` map to ensure proper PVC generation.

### Fixed
- Fixed "pod has unbound immediate PersistentVolumeClaims" error by providing explicit PV definitions for the database and app volumes.
- Separated database administrative secrets from application-specific schema credentials to improve security and configuration clarity.
- Corrected `.pgpass` file mounting point to `/opt/tomcat/.pgpass` to align with `tcdocker-iam` sub-project behavior.

## [1.0.5] - 2026-10-07
### Added
- Support for `standard` StorageClass and manual `PersistentVolume` (PV) definitions for local development.
- Included `db-data` in the global `volumes` map to ensure proper PVC generation.

### Fixed
- Fixed "pod has unbound immediate PersistentVolumeClaims" error by providing explicit PV definitions for the database and app volumes.

## [1.0.4] - 2026-10-04
### Added
- Added `schema-init` initContainer to `db-deployment.yaml` for automatic PostgreSQL schema migrations.
- Added support for Tomcat manager reload via `RELOAD_TOMCAT` environment variable and `build.sh` logic.
- Added `ssb_host_path`, `tomcat_mgr_user`, and `tomcat_mgr_pass` to `values.yaml`.
- Updated `Chart.yaml` icon to use a remote URL.

### Fixed
- Refactored helper functions in `_helpers.tpl` and updated all deployment templates to use the correct `tck8s-iam.fullname` logic.
- Corrected volume key naming in `values.yaml` to use hyphens instead of underscores.
- Added `namespace` field to `pvc.yaml` template.

### Changed
- Removed `secret.yaml` to move away from hardcoded secrets.
- Removed hardcoded `db.password` from `values.yaml` to improve security.
- Updated `app-deployment.yaml` and `db-deployment.yaml` to use dynamic volume mappings.

## [1.0.3] - 2026-09-29
### Added
- Automated secret generation and injection script (`scripts/setup_secrets.py`).
- Integration with Bitwarden CLI for automated vault population.
- Standardized secret naming and configuration in `values.yaml` to support automation.

## [1.0.2] - 2026-09-28
### Added
- Deployment files for **Bitwarden** (server, ui, worker, and database).
- Deployment files and configuration for the **External Secrets Operator (ESO)**.
- Added `bitwarden` and `externalSecretsOperator` configuration blocks to `values.yaml`.
- Added persistent volume claims (PVCs) for Bitwarden data and attachments.

## [1.0.1] - 2026-09-27
### Added
- Integrated **External Secrets Operator (ESO)** support for secret management.
- Added `SecretStore` and `ExternalSecret` templates to fetch secrets from **Bitwarden**.
- Added `configmap.yaml` template to manage non-sensitive application configurations.
- Added `externalSecrets` configuration block to `values.yaml`.

### Fixed
- Corrected `app-deployment.yaml` to use the correct template helper (`tck8s-iam.fullname` instead of `tomcat-app.fullname`).
- Removed hardcoded database password and credentials from `values.yaml` and `secret.yaml` to improve security.
- Corrected reference to the ConfigMap in `app-deployment.yaml`.

### Changed
- Refactored secret handling to be managed by the External Secrets Operator.
- Standardized helper usage across all deployment templates.
