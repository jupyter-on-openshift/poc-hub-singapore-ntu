FROM myproject/minimal-notebook:latest

USER root

# Required for ffmpeg.

RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    yum-config-manager -y --add-repo https://negativo17.org/repos/epel-multimedia.repo && \
    yum install --enablerepo=epel -y ladspa fribidi ffmpeg && \
    yum -y clean all --enablerepo='*'

USER 1001
