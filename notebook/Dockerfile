FROM myproject/minimal-notebook:latest

USER root

# Required for ffmpeg.

RUN wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    rpm -ivh epel-release-latest-7.noarch.rpm && \
    rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm && \
    yum --enablerepo=epel install ffmpeg ffmpeg-devel -y && \
    yum -y clean all --enablerepo='*'

USER 1001
