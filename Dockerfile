FROM ubuntu:22.04

RUN apt update && apt upgrade -y \
    && apt install -y \
    build-essential \
    autoconf automake libtool \
    pkg-config git \
    python3.10 python3.10-dev python3-pip \
    # clean up image
    && apt clean \
    && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

# install cython
# WORKDIR /tmp
# RUN git clone https://github.com/cython/cython
# WORKDIR /tmp/cython
# RUN python3 setup.py build \
#     && python3 setup.py install \
#     && make
RUN pip3 install cython

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
# WORKDIR /tmp

# RUN git clone https://github.com/vapoursynth/vapoursynth.git

# WORKDIR /tmp/vapoursynth

# RUN bash autogen.sh \
#     && ./configure \
#     && make -j${JOBS} \
#     && make install
