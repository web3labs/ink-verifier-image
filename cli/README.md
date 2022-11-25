# Verifiable Build CLI

## Install

Using the Git repository
```
cargo install --git https://github.com/web3labs/ink-verifier-image.git
```

or from source
```
cargo install --path .
```

## Run

First pull the docker image for reproducible builds
```
docker pull ghcr.io/web3labs/ink-verifier:latest
```

Then run the tool
```
❯ build-verifiable-ink /path/to/contract
```

If you built the docker image locally, you can run the tool by specifying the tag you used for building.
For example:
```
❯ build-verifiable-ink -t develop /path/to/contract
```

You can also run the tool without building or pulling the docker image. In this case, specify the published image using the `--image` or `-i` flag.
For example:
```
❯ build-verifiable-ink -i ghcr.io/web3labs/ink-verifier /path/to/contract
```

### Notes

To avoid problems with file system permissions we recommend the use of [Podman](https://podman.io/) as container engine.

You can specify the container engine in the command line tool options:
```
❯ build-verifiable-ink --help
A command line interface to generate verifiable source code packages.

Usage: build-verifiable-ink [OPTIONS] <SOURCE>

Arguments:
  <SOURCE>  Source directory, can be relative; e.g. '.'

Options:
  -i, --image <IMAGE>        Ink! verifier image name [default: ink-verifier]
  -t, --tag <TAG>            Ink! verifier image tag [default: latest]
      --engine <ENGINE>      Container engine [default: docker]
      --env-file <ENV_FILE>  Environment file
  -h, --help                 Print help information
  -V, --version              Print version information
```