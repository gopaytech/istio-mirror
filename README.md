# istio-mirror

Mirrors Istio images from Docker Hub to GHCR, so clusters can pull them without hitting Docker Hub rate limits.

| Source | Mirror |
| --- | --- |
| `docker.io/istio/pilot:<version>[-distroless]` | `ghcr.io/gopaytech/istio-mirror/pilot:<version>[-distroless]` |
| `docker.io/istio/proxyv2:<version>[-distroless]` | `ghcr.io/gopaytech/istio-mirror/proxyv2:<version>[-distroless]` |

All platforms are copied, and the mirrored digests are the same as upstream.

## Adding a version

Add the version to [`tags.txt`](tags.txt) and push to `main`. The [`mirror`](.github/workflows/mirror.yml) workflow copies both `<version>` and `<version>-distroless` for each image. Images that are already mirrored get skipped.

To mirror a version once without editing `tags.txt`, run the workflow manually and set the `versions` input.

If anonymous pulls from Docker Hub get rate limited, add `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` as repository secrets.

## Using the mirror

```sh
istioctl install \
  --set hub=ghcr.io/gopaytech/istio-mirror \
  --set tag=1.31.0 \
  --set values.global.variant=distroless
```

With Helm, set `global.hub`, `global.tag` and `global.variant`.
