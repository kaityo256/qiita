FROM archlinux
MAINTAINER kaityo256

ENV USER user
ENV HOME /home/${USER}
ENV SHELL /bin/bash

RUN useradd -m ${USER}
RUN echo 'user:userpass' | chpasswd

RUN pacman -Syyu --noconfirm
RUN pacman -S --noconfirm \
  aarch64-linux-gnu-gcc \
  git \
  vim \
  qemu \
  qemu-arch-extra

USER ${USER}
WORKDIR /home/${USER}
