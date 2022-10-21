# Security Notes

## Docker

To run Docker in a secure way we follow the OWASP https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html

### Rootless Docker

Run the Docker daemon and containers as a non-root user to mitigate potential vulnerabilities in the daemon and the container runtime.

Instructions at https://docs.docker.com/engine/security/rootless/

## Podman

You can use [Podman](https://podman.io/) as a secure Docker alternative. It runs rootless out of the box.

**Tip**
In `/etc/containers/registries.conf`
```
[registries.search]
registries = ['docker.io']
```
