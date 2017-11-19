FROM golang as build

ARG goarch
ENV GOARM=6

# add things we need
RUN go get -v github.com/Masterminds/glide

RUN mkdir /go/src/github.com/innovate-technologies/Dispatch
RUN git clone https://github.com/innovate-technologies/Dispatch.git /go/src/github.com/innovate-technologies/Dispatch

WORKDIR /go/src/github.com/innovate-technologies/Dispatch

RUN glide install
RUN cd dispatchd && GOARCH=${goarch} go build -v ./ && cd ..
RUN cd dispatchctl && GOARCH=${goarch} go build -v ./ && cd ..


ARG imagearch=amd64
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
COPY --from=build /go/src/github.com/innovate-technologies/Dispatch/dispatchd/dispatchd  /usr/bin/dispatchd 
COPY --from=build /go/src/github.com/innovate-technologies/Dispatch/dispatchd/dispatchctl  /usr/bin/dispatchctl                                                                                         

RUN systemctl enable docker.service
RUN systemctl enable dispatchd.service

VOLUME [ "/run/metadata/dispatch" ]

CMD ["/usr/sbin/init"]