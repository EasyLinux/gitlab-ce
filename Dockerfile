FROM ubuntu:20.04
LABEL author="Serge NOEL <serge.noel@easylinux.fr>"

# Edit those parameter before building
# goarch="<amd|ppc6Ele|arm64>
ARG goarch=ppc64le
# nodearch="<amd|ppc64le|arm64>
ARG nodearch=ppc64le


RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install sudo -y


# install basic package #
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libre2-dev \
    libreadline-dev libncurses5-dev libffi-dev curl openssh-server checkinstall libxml2-dev \
    libxslt-dev libcurl4-openssl-dev libicu-dev logrotate rsync python-docutils pkg-config cmake runit
  
# install git
RUN apt-get install -y libcurl4-openssl-dev libexpat1-dev gettext libz-dev libssl-dev libpcre2-dev build-essential git
RUN mkdir /build 
WORKDIR /build
RUN git clone https://gitlab.com/gitlab-org/gitaly.git -b 13-6-stable gitaly
RUN cd gitaly \
    && make git GIT_PREFIX=/usr/local
RUN apt-get remove -y git
RUN git --version

# Install other tools 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y graphicsmagick postfix libimage-exiftool-perl

# Install ruby
RUN apt-get -y remove ruby1.8
RUN wget https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.2.tar.gz \
    && tar zxf ruby-2.7.2.tar.gz \
    && cd ruby-2.7.2 \
    && ./configure --disable-install-rdoc \
    && make \
    && make install

# Install go
RUN rm -rf /usr/local/go
RUN wget https://dl.google.com/go/go1.13.5.linux-${goarch}.tar.gz
RUN tar -C /usr/local -zxf go1.13.5.linux-${goarch}.tar.gz
RUN ln -sf /usr/local/go/bin/{go,godoc,gofmt} /usr/local/bin/

# Install node et yarn   arm64 x64
RUN wget https://nodejs.org/download/release/v14.15.4/node-v14.15.4-linux-${nodearch}.tar.gz
RUN tar zxf node-v14.15.4-linux-${nodearch}.tar.gz
RUN cd node-v14.15.4-linux-${nodearch} \
    && cp -r * /usr 

RUN wget https://classic.yarnpkg.com/latest.tar.gz 
RUN tar -C /usr/local -zxf latest.tar.gz
RUN ln -s /usr/local/yarn-v1.22.5/bin/yarn /usr/local/bin/yarn
RUN yarn --version

# Creation utilisateur
RUN adduser --disabled-login --gecos 'GitLab' git
RUN echo "# Allow git to execute any command without password" >> /etc/sudoers
RUN echo "git	ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
USER git
WORKDIR /home/git

# Récupérer les sources
RUN git clone https://gitlab.com/gitlab-org/gitlab-foss.git -b 13-6-stable gitlab
WORKDIR /home/git/gitlab
USER root
COPY Files/ /
RUN apt-get install -y tree
RUN chown -R git: /home/git/*
RUN ls -l config
RUN chmod 0600 config/secrets.yml
RUN chmod -R u+rwX,go-w log/
RUN chmod -R u+rwX tmp/
RUN chmod -R u+rwX tmp/pids/
RUN chmod -R u+rwX tmp/sockets/
USER git
RUN mkdir -p public/uploads/
RUN chmod 0700 public/uploads
RUN chmod -R u+rwX builds/
RUN chmod -R u+rwX shared/artifacts/
RUN chmod -R ug+rwX shared/pages/
RUN sudo git config --global core.autocrlf input
RUN sudo git config --global gc.auto 0
RUN sudo git config --global repack.writeBitmaps true
RUN sudo git config --global receive.advertisePushOptions true
RUN sudo git config --global core.fsyncObjectFiles true

# Installation
RUN sudo apt-get install -y libpq-dev postgresql-server-dev-12
RUN sudo chown git: /home/git
#RUN bundle config set without 'development test mysql aws kerberos' \
#    && bundle install



# EXPOSE 443 80 22

#WORKDIR /
#COPY wrapper.sh wrapper.sh
#ENTRYPOINT bash ./wrapper.sh

