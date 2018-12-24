# Multistage builds to reduce image size to ~37MB
# by tuanhtrng
FROM alpine:latest as builder

MAINTAINER borland502 <jack.ryan.cia.gov@gmail.com>

WORKDIR /tmp

# Install dependencies
RUN apk add --no-cache \
    build-base \
    ctags \
    git \
    libx11-dev \
    libxpm-dev \
    libxt-dev \
    make \
    ncurses-dev \
    python3 \
    python3-dev

# Build vim from git source
RUN git clone https://github.com/vim/vim \
 && cd vim \
 && ./configure \
    --disable-gui \
    --disable-netbeans \
    --enable-multibyte \
    --enable-python3interp=yes \
    --enable-cscope \
    --with-features=huge \
 && make install

 FROM alpine:latest

 COPY --from=builder /usr/local/bin/ /usr/local/bin
 COPY --from=builder /usr/local/share/vim/ /usr/local/share/vim/
 # NOTE: man page is ignored

 RUN apk add --no-cache \
    diffutils \
    libice \
    libsm \
    libx11 \
    libxt \
    ncurses

ENTRYPOINT ["vim"]
