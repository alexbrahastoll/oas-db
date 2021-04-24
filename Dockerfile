FROM ubuntu:20.04
SHELL ["/bin/bash", "-c"]
ARG DEBIAN_FRONTEND="noninteractive"
ENV TZ="america/sao_paulo"

RUN apt-get update && \
  apt-get install -y \
  wget
RUN dpkg --purge packages-microsoft-prod && \
  wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
  dpkg -i packages-microsoft-prod.deb && \
  apt-get update && \
  apt-get install -y \
  apt-transport-https \
  build-essential \
  curl \
  dotnet-sdk-5.0 \
  gcc \
  git \
  libbz2-dev \
  libffi-dev \
  liblzma-dev \
  libncurses5-dev \
  libncursesw5-dev \
  libreadline-dev \
  libsqlite3-dev \
  libssl-dev \
  llvm \
  make \
  python-openssl \
  tk-dev \
  vim \
  xz-utils \
  zlib1g \
  zlib1g-dev
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf && \
  cd ~/.asdf && \
  git checkout "$(git describe --abbrev=0 --tags)"
ENV PATH="~/.asdf/shims:~/.asdf/bin:$PATH"
RUN asdf plugin-add python && \
  asdf plugin-add ruby && \
  asdf plugin-update --all && \
  asdf install python 3.8.2 && \
  asdf global python 3.8.2 && \
  asdf install ruby 2.7.2 && \
  asdf global ruby 2.7.2
RUN python3 -m ensurepip && \
  pip3 install --upgrade pip
RUN git clone https://github.com/microsoft/restler-fuzzer.git ~/restler-fuzzer && \
  mkdir ~/restler-fuzzer-bin && \
  cd ~/restler-fuzzer && \
  pip3 install requests && \
  pip3 install applicationinsights && \
  python ./build-restler.py --dest_dir ~/restler-fuzzer-bin

COPY . /root/oas_db
RUN cd ~/oas_db && \
  bundle install
RUN mkdir ~/oas_db_logs
