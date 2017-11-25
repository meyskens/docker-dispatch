Dispatch inside a container
===========================

This Docker container runs full systemd with Docker and Dispatch inside a privileged container.

## How to run
`docker run --privileged -it -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v maartje/dispatch:amd64-0.0.8`