FROM nvcr.io/nvidia/tensorrt:23.12-py3

RUN apt update && apt upgrade -y \
    && apt install -y \
    build-essential autoconf automake libtool \
    cmake git-core libass-dev libfreetype6-dev libgnutls28-dev libmp3lame-dev libsdl2-dev \
    libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev \
    meson ninja-build pkg-config git texinfo yasm zlib1g-dev libunistring-dev \
    python3.10 python3.10-dev python3-pip \
    # encoder (command example: x264 x265 SvtAv1EncApp)
    libnuma-dev \
    # clean up image
    && apt clean \
    && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

# install cython
RUN pip install --upgrade pip \
    && pip install cython

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

### include文が足りないので追加
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
    && make install

# install ffmpeg
WORKDIR /tmp
RUN mkdir ffmpeg_sources
ENV FFMPEG_SRC_ROOT=/tmp/ffmpeg_sources

## install nasm
WORKDIR $FFMPEG_SRC_ROOT
RUN wget https://www.nasm.us/pub/nasm/releasebuilds/2.16.01/nasm-2.16.01.tar.bz2 \
    && tar xjvf nasm-2.16.01.tar.bz2
WORKDIR $FFMPEG_SRC_ROOT/nasm-2.16.01
RUN ./autogen.sh \
    && ./configure \
    && make -j${JOBS} \
    && make install

## install libx264
WORKDIR $FFMPEG_SRC_ROOT
RUN git -C x264 pull 2> /dev/null || git clone --depth 1 https://code.videolan.org/videolan/x264.git
WORKDIR $FFMPEG_SRC_ROOT/x264
RUN ./configure --enable-static --enable-pic \
    && make -j${JOBS} \
    && make install

## install libx265
WORKDIR $FFMPEG_SRC_ROOT
RUN wget -O x265.tar.bz2 https://bitbucket.org/multicoreware/x265_git/get/master.tar.bz2 \
    && mkdir x265 && tar xjvf x265.tar.bz2 -C x265 --strip-components 1
WORKDIR $FFMPEG_SRC_ROOT/x265/build/linux
RUN cmake -G "Unix Makefiles" -DENABLE_SHARED:bool=off ../../source \
    && make -j${JOBS} \
    && make install

## install svtav1
WORKDIR $FFMPEG_SRC_ROOT
RUN git -C SVT-AV1 pull 2> /dev/null || git clone https://gitlab.com/AOMediaCodec/SVT-AV1.git \
    && mkdir -p $FFMPEG_SRC_ROOT/SVT-AV1/build
WORKDIR $FFMPEG_SRC_ROOT/SVT-AV1/build
RUN cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DBUILD_DEC=OFF -DBUILD_SHARED_LIBS=OFF .. \
    && make -j${JOBS} \
    && make install

## install vmaf
WORKDIR $FFMPEG_SRC_ROOT
RUN wget https://github.com/Netflix/vmaf/archive/v2.3.1.tar.gz \
    && tar xzvf v2.3.1.tar.gz \
    && mkdir -p vmaf-2.3.1/libvmaf/build
WORKDIR $FFMPEG_SRC_ROOT/vmaf-2.3.1/libvmaf/build
RUN meson setup -Denable_tests=false -Denable_docs=false --buildtype=release --default-library=static .. \
    && ninja \
    && ninja install

## install libfdk-aac
WORKDIR $FFMPEG_SRC_ROOT
RUN git -C fdk-aac pull 2> /dev/null || git clone --depth 1 https://github.com/mstorsjo/fdk-aac
WORKDIR $FFMPEG_SRC_ROOT/fdk-aac
RUN autoreconf -fiv \
    && CFLAGS="-fPIC" ./configure --enable-shared \
    && make -j${JOBS} \
    && make install

## install FFMPEG
WORKDIR $FFMPEG_SRC_ROOT
RUN wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 \
    && tar xjvf ffmpeg-snapshot.tar.bz2
WORKDIR $FFMPEG_SRC_ROOT/ffmpeg
RUN ./configure \
    --pkg-config-flags="--static" \
    --extra-libs="-lpthread -lm" \
    --ld="g++" \
    --bindir="$HOME/bin" \
    --enable-gpl \
    --enable-gnutls \
    --enable-libfdk-aac \
    --enable-libfreetype \
    --enable-libmp3lame \
    --enable-libsvtav1 \
    --enable-libvorbis \
    --enable-libx264 \
    --enable-libx265 \
    --enable-nonfree \
    && make -j${JOBS} \
    && make install

RUN mv ~/bin/* /usr/local/bin && rm -rf ~/bin

# install plugin bestsource
WORKDIR /tmp
RUN git clone https://github.com/vapoursynth/bestsource.git
WORKDIR /tmp/bestsource
RUN git clone https://github.com/sekrit-twc/libp2p.git
RUN meson build \
    && ninja -C build \
    && ninja -C build install

# install plugin 
WORKDIR /tmp
RUN git clone https://github.com/AmusementClub/vs-mlrt.git
WORKDIR /tmp/vs-mlrt/vstrt
### 参照先の書き換え
RUN sed -i "/set(VAPOURSYNTH_INCLUDE_DIRECTORY*/c set(VAPOURSYNTH_INCLUDE_DIRECTORY \/usr\/local\/include\/vapoursynth)" CMakeLists.txt
RUN sed -i "/set(TENSORRT_HOME*/c set(TENSORRT_HOME \/usr\/src\/tensorrt)" CMakeLists.txt
RUN sed -i "/set(CUDNN_HOME*/c set(CUDNN_HOME \/usr\/local\/cuda)" CMakeLists.txt
RUN mkdir build
WORKDIR /tmp/vs-mlrt/vstrt/build
RUN cmake .. \
    && make -j${JOBS} \
    && make install \
    && mv /usr/local/lib/libvstrt.so /usr/local/lib/vapoursynth/libvstrt.so

WORKDIR /root/
