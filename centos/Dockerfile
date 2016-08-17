FROM registry.gitlab.com/gbraad/centos:7
MAINTAINER Gerard Braad <me@gbraad.nl>

RUN yum install -y git rpm-build rpmdevtools createrepo

RUN mkdir /workspace
VOLUME /workspace

CMD ["bash"]
