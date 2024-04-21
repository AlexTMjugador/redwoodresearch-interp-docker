# This Dockerfile can be used with the following commands (setting the
# BUILDKIT_PROGRESS environment variable is optional but useful for
# troubleshooting the image):
# $ DOCKER_BUILDKIT=1 BUILDKIT_PROGRESS=plain docker build -t redwood-interp .
# $ docker run -it --rm --gpus all -p 3000:3000 -p 6789:6789 redwood-interp

# The NodeJS and Python versions come from the .tool-versions repository file
FROM python:3.9.6-bullseye
ARG NODE_VERSION=16.13.0

ARG INTERPRETABILITY_MODELS_DIR=/rr-models
ARG DEBIAN_FRONTEND=noninteractive

LABEL org.opencontainers.image.description="Redwood Research's transformer interpretability tools (https://github.com/redwoodresearch/interp)"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source https://github.com/AlexTMjugador/redwoodresearch-interp-docker

# BuildKit is required for this heredoc syntax:
# https://docs.docker.com/engine/reference/builder/#here-documents
# https://docs.docker.com/build/buildkit/#getting-started
RUN <<-EOT
	set -e
	apt-get update
	apt-get install -yq --no-install-recommends awscli
	rm -rf /var/lib/apt/lists/*

	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
	. ~/.nvm/nvm.sh
	nvm install $NODE_VERSION
EOT

# Patch jaxlib and jax versions to avoid the following runtime error due to transitive
# dependencies accepting newer than expected jaxlib versions:
# "RuntimeError: jaxlib version 0.4.13 is newer than and incompatible with jax
# version 0.3.4. Please update your jax and/or jaxlib packages."
# The required jaxlib versions are no longer available on PyPi so changing versions
# slightly is needed. 0.3.5 does not work well for reasons described here:
# https://stackoverflow.com/questions/72109033/cannot-import-name-isin-python-with-jax
# Also, the -f parameter has to be on a line separate to the package specification
RUN <<-EOT
	set -e

	git clone https://github.com/redwoodresearch/interp.git
	git -C interp checkout 261f52eb1433a3dcbd3ef4a8884f514de560b2b2

	. ~/.nvm/nvm.sh
	nvm use node
	npm -C interp/interp/app install
	npm cache clean --force

	patch interp/requirements.txt <<-'REQUIREMENTS_PATCH'
	--- requirements.txt    2023-10-17 21:23:57.442305543 +0200
	+++ requirements_fixed.txt      2023-10-17 22:20:19.972006067 +0200
	@@ -41,10 +41,11 @@ git+https://github.com/daniel-ziegler/tr
	 typeguard==2.13.3
	 watchdog==2.1.6
	 web-pdb==1.5.6
	-jax==0.3.4 -f https://storage.googleapis.com/jax-releases/jax_releases.html
	+-f https://storage.googleapis.com/jax-releases/jax_releases.html
	+jax==0.3.4
	 # want to add jax[cuda], but that doesn't work on CI because that doesn't have cuda?
	 # installing in pre_requirements_cpu.txt doesn't allow me to put [cuda] here
	-# jaxlib -f https://storage.googleapis.com/jax-releases/jax_releases.html
	+jaxlib==0.3.2
	 flax==0.4.0
	 seaborn==0.11.2
	 websockets~=10.1.0
REQUIREMENTS_PATCH
	pip install -r interp/pre_requirements.txt
	pip install -r interp/requirements.txt
	pip cache purge

	aws s3 cp s3://rrserve/interp-assets/models/ --no-sign-request "$INTERPRETABILITY_MODELS_DIR" --recursive
EOT

WORKDIR /interp

# The first line is necessary on my machine for the script to properly download
# the GPT-2 tokenizers. Apparently the src/transformers/utils/hub.py cached_path
# function returns None at src/transformers/tokenization_utils_base.py, line
# 1744, without raising exceptions
COPY <<EOF /entrypoint.sh
python3 -c 'import transformers; transformers.GPT2TokenizerFast.from_pretrained("gpt2")'
PYTHONPATH=. INTERPRETABILITY_MODELS_DIR="$INTERPRETABILITY_MODELS_DIR" python3 interp/local_dev.py --host 0.0.0.0 $@ &
. ~/.nvm/nvm.sh
npm -C interp/app run start | cat
EOF

ENTRYPOINT [ "/bin/bash", "-e", "/entrypoint.sh" ]
