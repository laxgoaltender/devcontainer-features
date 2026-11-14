
# Flux 2 (flux2)

Flux is a tool for keeping Kubernetes clusters in sync with sources of configuration (like Git repositories and OCI artifacts), and automating updates to configuration when there is new code to deploy.

## Example Usage

```json
"features": {
    "ghcr.io/laxgoaltender/devcontainer-features/flux2:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter an Flux 2 version. | string | latest |
| flux9s_version | Version of flux9s to install, or 'none' to skip. | string | latest |

## Customizations

### VS Code Extensions

- `Weaveworks.vscode-gitops-tools`



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/laxgoaltender/devcontainer-features/blob/main/src/flux2/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
