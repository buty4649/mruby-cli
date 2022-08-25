FROM rubylang/ruby:3.1-focal as base

ARG MRUBY_VERSION
ENV MRUBY_ROOT=/opt/mruby

RUN apt-get update -qq \
  && apt-get install -qqy gcc gcc-multilib clang curl \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && curl -L --fail --retry 3 --retry-delay 1 https://github.com/mruby/mruby/archive/${MRUBY_VERSION}.tar.gz -s -o - | tar zxf - \
  && mv mruby-${MRUBY_VERSION} ${MRUBY_ROOT}

WORKDIR /home/mruby/code

FROM base as mruby-cli

COPY . /home/mruby/code
RUN rake compile

FROM base

COPY --from=mruby-cli /opt/mruby/bin/mruby-cli /usr/local/bin

CMD ["/usr/local/bin/mruby-cli"]
