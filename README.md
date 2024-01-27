# VideoToolKit
This repository is a Docker and code sample for super-resolution using VapourSynth and vs-mlrt.<br>
このリポジトリは、VapourSynthとvs-mlrtを使った超解像を行うためのDocker&コードサンプルです。<br>
<br>
In this environment, TensorRT is used, but please build other libraries (vsov for OpenVINO, vsncnn for NCNN) as needed.<br>
この環境ではTensorRTを利用してますが、必要に応じて他のライブラリ(vsov:OpenVINO用やvsncnn:NCNN用)もビルドしてください。<br>


# Setup
```bash
# Create .env file
echo "JOBS=$(($(grep cpu.cores /proc/cpuinfo | sort -u | sed 's/[^0-9]//g') + 1))" > .env
# docker build
docker compose up -d --build
# join container
docker compose exec develop /bin/bash
# model convert
bash convert_model.sh /tmp/models/cugan/pro-conservative-up2x.onnx
# upconv & encode demo
# before executing, please place the video in the input directory.
cd src
python demo_trt.py
```
