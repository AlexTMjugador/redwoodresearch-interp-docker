#!/bin/sh -eu
docker system prune --volumes --all
DOCKER_BUILDKIT=1 BUILDKIT_PROGRESS=plain \
docker build -t ghcr.io/alextmjugador/redwoodresearch-interp:latest \
-t ghcr.io/alextmjugador/redwoodresearch-interp:261f52eb1433a3dcbd3ef4a8884f514de560b2b2 .
docker push ghcr.io/alextmjugador/redwoodresearch-interp --all-tags
