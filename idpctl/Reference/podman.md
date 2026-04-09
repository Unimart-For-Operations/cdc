---
source: idpctl
synced: 2026-04-09
---
# Podman Support (Experimental)

idpctl includes opt-in support for Podman as a container runtime. This is experimental and intended to allow developers who prefer "podman" over "docker" to safely preload images into a Kind cluster and run the IDP locally.

## How it works

- `podman` is detected via `idpctl` prereqs. Use `idpctl doctor` to see Podman status.
- Use `--container-runtime=podman` when running `idpctl up` to enable podman-specific image preloading.
- idpctl will scan the `idpbuilder/` repository for manifests (including the embedded ArgoCD install manifest) to discover image references and attempt to preload them into the Kind cluster so ArgoCD and other controllers do not hit ImagePullBackOff.

## Requirements

- `podman` CLI installed (install via Nix: `nix profile add nixpkgs#podman`)
- A running Podman VM (`podman machine init && podman machine start`) on macOS
- `kind` available on PATH

Note: On aarch64 macOS the `podman-docker` shim may not be available via nixpkgs; idpctl uses `podman` directly.

## Usage

```bash
# Run up with Podman preload behavior
idpctl up --container-runtime=podman

# Or explicitly generate configs and preload images manually
idpctl config generate --out ./.workspace/generated --org-dir .
```

## Troubleshooting

- If `podman machine init` fails to download the VM image, it may be due to quay.io being unavailable — retry later or use an alternate network to fetch the image.
- If image preload fails, idpctl will continue but ArgoCD pods may enter `ImagePullBackOff` until images are available in registries or preloaded into kind.
