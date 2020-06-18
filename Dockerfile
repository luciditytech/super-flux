FROM ruby:2.6.3-slim-stretch as Builder

ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN apt-get update
RUN apt-get install -y \
    build-essential \
    git \
    tzdata \
    automake \
    libtool \
    intltool \
    autoconf \
    pkg-config \
    curl \
    git \
    bash

WORKDIR /app

ADD . /app/

RUN bundle install

RUN groupadd -r super-flux && useradd -r -m -g super-flux super-flux
RUN chown -R super-flux:super-flux /app

USER super-flux
