ARG imagearch=amd64
FROM multiarch/debian-debootstrap:${imagearch}-stretch

ARG dispatch_version
ARG imagearch=amd64

# setup systemd
RUN apt-get -y update && apt-get -y upgrade && apt-get clean && \
		apt-get -y install apt-utils lsb-release curl git cron at logrotate rsyslog \
			unattended-upgrades ssmtp lsof locales procps \
			initscripts libsystemd0 libudev1 systemd sysvinit-utils udev util-linux && \
		dpkg-reconfigure locales && \
		apt-get clean

# setup systemd
ENV container docker 
RUN cd /lib/systemd/system/sysinit.target.wants/ && \
		ls | grep -v systemd-tmpfiles-setup.service | xargs rm -f && \
		rm -f /lib/systemd/system/sockets.target.wants/*udev* && \
		systemctl mask -- \
			tmp.mount \
			etc-hostname.mount \
			etc-hosts.mount \
			etc-resolv.conf.mount \
			-.mount \
			swap.target \
			getty.target \
			getty-static.service \
			dev-mqueue.mount \
			systemd-tmpfiles-setup-dev.service \
			systemd-remount-fs.service \
			systemd-ask-password-wall.path \
			systemd-logind.service && \
		systemctl set-default multi-user.target || true
RUN sed -ri /etc/systemd/journald.conf \
			-e 's!^#?Storage=.*!Storage=volatile!'

VOLUME [ "/sys/fs/cgroup", "/run", "/run/lock", "/tmp" ]

# add docker
RUN curl https://get.docker.com | bash

COPY dispatchd.service /etc/systemd/system/dispatchd.service
RUN case "${imagearch}" in                                                                                 \
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
      echo "Unhandled architecture: ${imagearch}."; exit 1;                                                \
      ;;                                                                                              \
    esac                                                                                              

RUN systemctl enable docker.service
RUN systemctl enable dispatchd.service

VOLUME [ "/run/metadata/dispatch" ]

CMD ["/lib/systemd/systemd"]