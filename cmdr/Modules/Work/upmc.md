---
source: cmdr
synced: 2026-04-09
---
# UPMC Work Module

This module contains all UPMC-specific configurations for work machines.

## What's Included

- **Git Configuration** - Work email and GitLab integration
- **SSH Configuration** - All UPMC bastion hosts and AWS SSM connections
- **Environment Variables** - Vault, GitLab, AWS, CrowdStrike, SonarQube
- **Shell Functions** - AWS profile switching, Vault SSH signing

## Usage

Import in host configuration:

Work hosts set `work = true;` in their `meta.nix`. The discovery engine
automatically imports the UPMC module and appropriate platform variant.

```nix
# home/02-hosts/macos/apple-macbook-m3-pro/meta.nix
{
  # ...
  work = true;
}
```

## Architecture

The module is split into focused submodules:

- `git.nix` - Git email and GitLab service configuration
- `ssh.nix` - All UPMC bastion hosts (dev, stg, prd, foo, beta, drx, vault)
- `env.nix` - Environment variables (Vault, GitLab, AWS, security tools)
- `shell-functions.nix` - Interactive shell helpers (AWS, Vault, Kubernetes)

## Security Note

⚠️ **WARNING**: This module contains UPMC-specific tokens and credentials.
- GitLab tokens
- CrowdStrike client secrets
- SonarQube tokens
- AWS profile configurations

These should eventually be migrated to encrypted secret management (sops-nix or age).

## Environments

SSH bastions are organized by environment:
- **dev** - Development environment
- **tst** - Testing environment
- **stg** - Staging environment
- **prd** - Production environment (us-east-1)
- **drx** - Disaster Recovery (us-west-2)
- **foo** - Beta environment
- **vault** - Vault POC bastion
