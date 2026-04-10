---
source: idpctl
synced: 2026-04-10
---
# Podman Setup (macOS)

This guide covers installing and starting the Podman VM on macOS so you can use `idpctl --container-runtime=podman`.

1. Install Podman via Nix (preferred):

```bash
nix profile add nixpkgs#podman
```

2. Initialize and start the Podman VM:

```bash
podman machine init
podman machine start
```

3. Verify Podman is running:

```bash
podman info
```

4. Use idpctl with Podman:

```bash
idpctl up --container-runtime=podman
```

Notes:
- If `podman machine init` fails to download the VM image, it attempts to pull the image from `quay.io/podman/machine-os`. If quay is unavailable, retry or use an alternate network.
- On aarch64 macOS `podman-docker` may not be available via nixpkgs; idpctl uses `podman` directly and does not require a `docker` socket.
