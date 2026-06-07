FROM alpine:3.19

RUN apk add --no-cache \
  build-base \
  automake \
  autoconf \
  libtool \
  pkgconfig \
  postgresql-dev \
  curl

# Build sysbench from source
RUN curl -L https://github.com/akopytov/sysbench/archive/1.0.20.tar.gz -o sysbench.tar.gz \
  && tar xzf sysbench.tar.gz \
  && cd sysbench-1.0.20 \
  && ./autogen.sh \
  && ./configure --with-pgsql \
  && make -j$(nproc) \
  && make install

ENTRYPOINT ["sysbench"]

