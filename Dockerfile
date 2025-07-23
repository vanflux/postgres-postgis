ARG BASE_IMAGE="postgres:16-alpine3.22"
FROM ${BASE_IMAGE}

# Based on https://github.com/postgis/docker-postgis/blob/99857b2d3bf08b19ef4dcf1b21fdbf7dbe0faaa8/16-3.5/alpine/Dockerfile
RUN set -eux \
    && apk add --no-cache --virtual .fetch-deps ca-certificates openssl tar \
    && wget -O postgis.tar.gz "https://github.com/postgis/postgis/archive/3.5.3.tar.gz" \
    && mkdir -p /usr/src/postgis \
    && tar --extract --file postgis.tar.gz --directory /usr/src/postgis --strip-components 1 \
    && rm postgis.tar.gz \
    && apk add --no-cache --virtual .build-deps gdal-dev geos-dev proj-dev proj-util \
      sfcgal-dev $DOCKER_PG_LLVM_DEPS autoconf automake cunit-dev file g++ gcc gettext-dev \
      git json-c-dev libtool libxml2-dev make pcre2-dev perl protobuf-c-dev \
    # build postgis with Link Time Optimization (LTO) enabled
    && cd /usr/src/postgis \
    && gettextize \
    && ./autogen.sh \
    && ./configure --enable-lto \
    && make -j$(nproc) \
    && make install \
    # install postgis dependencies
    && apk add --no-cache --virtual .postgis-rundeps \
        gdal \
        geos \
        proj \
        sfcgal \
        json-c \
        libstdc++ \
        pcre2 \
        protobuf-c \
        ca-certificates \
    # clean
    && cd / \
    && rm -rf /usr/src/postgis \
    && apk del .fetch-deps .build-deps
