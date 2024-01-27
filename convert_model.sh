#! /bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <model_dir>"
    exit 1
fi

MODEL_DIR=$1
OUT_DIR=/trtengine

mkdir -p $OUT_DIR

function convert_onnx2trt () {
    OUT_PATH=${OUT_DIR}/$(basename $1 .onnx).engine
    trtexec --onnx=$1 --minShapes=input:1x3x8x8 --optShapes=input:1x3x64x64 --maxShapes=input:1x3x1080x1920 --saveEngine=$OUT_PATH --tacticSources=+CUDNN,-CUBLAS,-CUBLAS_LT --fp16 --workspace=4096
}

TARGET_DIR=${MODEL_DIR}/cugan

for filepath in $TARGET_DIR/*; do
  echo $filepath
  convert_onnx2trt $filepath
  break
done
