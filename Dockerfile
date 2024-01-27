FROM nvcr.io/nvidia/tensorrt:23.12-py3

RUN apt update && apt upgrade -y \
    && apt install -y \
    build-essential autoconf automake libtool \
    cmake git-core libass-dev libfreetype6-dev libgnutls28-dev libmp3lame-dev libsdl2-dev \
    libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev \
    meson ninja-build pkg-config git texinfo yasm zlib1g-dev \
    python3.10 python3.10-dev python3-pip \
    # encoder (command example: x264 x265 SvtAv1EncApp)
    x264 x265 svt-av1 \
    # clean up image
    && apt clean \
    && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

# install cython
RUN pip install --upgrade pip

# install libp2p
RUN git clone https://github.com/libp2p/cpp-libp2p.git
WORKDIR /tmp/cpp-libp2p

RUN mkdir build
WORKDIR build
RUN cmake .. \
    && make -j${JOBS} \
    && make install

# install zimg
WORKDIR /tmp
RUN git clone https://github.com/sekrit-twc/zimg.git
WORKDIR /tmp/zimg
RUN git submodule update --init --recursive
RUN bash autogen.sh \
    && ./configure \
    && make -j${JOBS} \
    && make install \
    && ldconfig 

# install vapoursynth
WORKDIR /tmp

RUN git clone https://github.com/vapoursynth/vapoursynth.git

WORKDIR /tmp/vapoursynth

# include分が足りないので追加
RUN sed -i '1s/^/#include <atomic>\n/' src/core/audiofilters.cpp

RUN bash autogen.sh \
    && ./configure \
    && make -j${JOBS} \
    && make install \
    && ldconfig 

ENV PYTHONPATH /usr/local/lib/python3.10/site-packages:$PYTHONPATH

# install jansson
WORKDIR /tmp
RUN wget https://digip.org/jansson/releases/jansson-2.13.tar.gz \
    && tar -zxvf jansson-2.13.tar.gz
WORKDIR /tmp/jansson-2.13
RUN ./configure \
    && make -j${JOBS} \
    && make check
    && make install

# install bestsource
# WORKDIR /tmp
# RUN git clone https://github.com/vapoursynth/bestsource.git
# WORKDIR /tmp/bestsource
# RUN git clone https://github.com/sekrit-twc/libp2p.git
# RUN meson build

WORKDIR /root/
