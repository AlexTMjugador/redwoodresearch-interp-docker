<div align="center">
<img src="placeholder" alt="redwoodresearch-interp-docker logo" width="300" height="300">
<h1>redwoodresearch-interp-docker</h1>

<i>Redwood Research's transformer interpretability tools, conveniently packaged
in a Docker container for simple and reproducible deployments.</i>

</div>

This repository provides a simple `Dockerfile` defining an image containing a
clean, functioning installation of [Redwood Research's transformer
interpretability tools](https://github.com/redwoodresearch/interp). Setting up
these tools across different environments can be challenging due to numerous
assumptions about the running environment, but this Docker image simplifies that
process.

The `build.sh` script facilitated the upload of the image to the GitHub Packages
container registry, where a prebuilt version of the defined Docker image is
stored.

# ✨ Getting started

The quickest way to utilize this Docker image is by pulling it from the [GitHub
Packages](https://github.com/features/packages) container registry. Before
pulling the image, ensure that your Docker daemon is [authenticated to the
GitHub Packages container
registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-to-the-container-registry).
The following commands perform this authentication and start a throwaway
container with the image:

```shell
$ docker login ghcr.io -u <your GitHub user>
$ docker run -it --rm --gpus all -p 3000:3000 -p 6789:6789 ghcr.io/alextmjugador/redwoodresearch-interp
```

If everything goes smoothly, running the above commands will launch the
interpretability web UI on port 3000. The interpretability tools were not
modified, so all details regarding how they function apply to this Docker
container. Enjoy your interpretability session!
