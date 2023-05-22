# SimplyCode Docker

[![SimplyEdit][simplyedit-shield]][simplyedit-site]
[![][project-stage-badge: Experimental]][project-stage-page]
[![License][license-shield]][license-link]
[![standard-readme compliant][standard-readme-shield]][standard-readme-link]

Docker environment to create **SimplyCode** applications in.

## Install

To use the docker image, pull it from the GitHub Container Registry (ghcr.io).

A `latest` version is not tagged for [various reasons](https://vsupalov.com/docker-latest-tag/). To use the latest version, use the `main` tag:

```sh
docker pull ghcr.io/simplyedit/simplycode-docker:main
```

Versioned images are also available:

```sh
docker pull ghcr.io/simplyedit/simplycode-docker:v0.3.0
```

## Usage

For most use cases, the following command should be enough:

```sh
docker run \
    --env "USER_GID=$(id -g)" \
    --env "USER_ID=$(id -u)" \
    --interactive \
    --rm \
    --tty \
    --volume "${PWD}:/var/www/www/api/data" \
    ghcr.io/simplyedit/simplycode-docker:main
```

This will mount the current working directory into the docker image at the right place, and start the SimplyCode server.

## Contribute

Feedback and contributions are welcome. Please open an issue or pull request.

### Development

This repository should not have any significant code.

Currently, the only code is:

- `Dockerfile` that builds a docker image with SimplyCode installed
- `entrypoint.sh` that is used to run SimplyCode in the Docker image (and do some checks)
- `.github/workflows/publish.yml` GitHub workflow that builds and publishes the docker image 

## License

Created by [SimplyEdit](https://simplyedit.io) under an MIT License.

[license-link]: ./LICENSE
[license-shield]: https://img.shields.io/github/license/simplyedit/simplycode-docker.svg
[simplyedit-shield]: https://img.shields.io/badge/Simply-Edit-F26522?labelColor=939598
[simplyedit-site]: https://simplyedit.io/
[project-stage-badge: Experimental]: https://img.shields.io/badge/Project%20Stage-Experimental-yellow.svg
[project-stage-page]: https://blog.pother.ca/project-stages/
[standard-readme-link]: https://github.com/RichardLitt/standard-readme
[standard-readme-shield]: https://img.shields.io/badge/-Standard%20Readme-brightgreen.svg
