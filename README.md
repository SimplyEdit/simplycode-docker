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

When using Docker Desktop, it is advised to use the `--publish-all` flag to make the SimplyCode server available on the host machine.

That way, the SimplyCode server can be accessed by using the "Open in Browser" button in Docker Desktop.

![img.png][1]

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

[1]: data:image/png;base64,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
