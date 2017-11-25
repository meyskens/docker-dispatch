FROM golang as build

ARG goarch
ENV GOARM=6

# add things we need
RUN go get -v github.com/Masterminds/glide

RUN mkdir -p /go/src/github.com/innovate-technologies/Dispatch
RUN git clone https://github.com/innovate-technologies/Dispatch.git /go/src/github.com/innovate-technologies/Dispatch

WORKDIR /go/src/github.com/innovate-technologies/Dispatch

RUN glide install
RUN cd dispatchd && GOARCH=${goarch} go build -v ./ && cd ..
RUN cd dispatchctl && GOARCH=${goarch} go build -v ./ && cd ..


ARG imagearch
FROM multiarch/debian-debootstrap:${imagearch}-stretch

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
COPY --from=build /go/src/github.com/innovate-technologies/Dispatch/dispatchd/dispatchd  /usr/bin/dispatchd 
COPY --from=build /go/src/github.com/innovate-technologies/Dispatch/dispatchctl/dispatchctl  /usr/bin/dispatchctl                                                                                         

RUN systemctl enable docker.service
RUN systemctl enable dispatchd.service

VOLUME [ "/run/metadata/dispatch" ]

CMD ["/lib/systemd/systemd"]