ARG imagearch
FROM ${imagearch}/centos:7

ARG dispatch_version

# setup systemd
ENV container docker 
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \ 
    rm -f /lib/systemd/system/multi-user.target.wants/*;\
    rm -f /etc/systemd/system/*.wants/*;\
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*;\
    rm -f /lib/systemd/system/anaconda.target.wants/*; 
VOLUME [ "/sys/fs/cgroup" ] 

# add docker
RUN curl https://get.docker.com | bash

COPY dispatchd.service /etc/systemd/system/dispatchd.service
RUN case "${ARCH}" in                                                                                 \
    armv7l|armhf|arm)                                                                                 \
      curl -Ls https://github.com/innovate-technologies/Dispatch/releases/download/${dispatch_version}/dispatchctl-linux-arm > /usr/bin/dispatchctl && \
      chmod +x /usr/bin/dispatchctl                                                                   \
      ;;                                                                                              \
    amd64|x86_64)                                                                                     \
      curl -Ls https://github.com/innovate-technologies/Dispatch/releases/download/${dispatch_version}/dispatchctl-linux-amd64 > /usr/bin/dispatchctl && \
      chmod +x /usr/bin/dispatchctl                                                                   \
      ;;                                                                                              \
    arm64|aarch64)                                                                                    \
      curl -Ls https://github.com/innovate-technologies/Dispatch/releases/download/${dispatch_version}/dispatchctl-linux-arm64 > /usr/bin/dispatchctl && \
      chmod +x /usr/bin/dispatchctl                                                                   \
      ;;                                                                                              \
    *)                                                                                                \
      echo "Unhandled architecture: ${ARCH}."; exit 1;                                                \
      ;;                                                                                              \
    esac                                                                                              

RUN systemctl enable docker.service
RUN systemctl enable dispatchd.service

VOLUME [ "/run/metadata/dispatch" ]

CMD ["/usr/sbin/init"]