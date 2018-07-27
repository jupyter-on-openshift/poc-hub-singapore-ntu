FROM myproject/minimal-notebook:latest

USER root

# Required for ffmpeg.

RUN yum -y install epel-release && \
    rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm && \
    yum install ffmpeg ffmpeg-devel -y && \
    yum -y clean all --enablerepo='*'

USER 1001
