import subprocess
import pathlib

import vapoursynth as vs

import vsmlrt

INPUT_DIR = "../input"
OUTPUT_DIR = "../output"

OUT_EXT = ".mp4"

ENGINE_PATH = "/trtengine/pro-conservative-up2x.engine"

if __name__ == "__main__":
    input_dir_path = pathlib.Path(INPUT_DIR)
    output_dir_path = pathlib.Path(OUTPUT_DIR)

    file_path_list = [p for p in list(input_dir_path.glob("*")) if p.name not in [".gitkeep"]]

    for file_path in file_path_list:
        video = vs.core.bs.VideoSource(source=str(file_path))
        video = vs.core.std.SelectEvery(video, cycle=2, offsets=[0])  # fpsを半分にする
        video = video.resize.Point(format=vs.RGBS)  # モデルが読み込めるようにRGBSに変換
        video = vs.core.trt.Model(video, engine_path=ENGINE_PATH, tilesize=[video.width, video.height])  # CUGANでアップスケール
        video = video.resize.Point(format=vs.YUV420P8, matrix_s="709")  # ffmpegへストリーム出来るようにYUV420P8に変換

        output_path = output_dir_path / f"{file_path.stem}{OUT_EXT}"
        ffmpeg_cmd = ["ffmpeg",
                "-i", "-",
                "-vcodec", "libx265",
                "-crf", "23",
                "-preset", "medium",
                "-pix_fmt", "yuv420p",
                "-tune", "animation",
                f"{str(output_path)}"]
        print(ffmpeg_cmd)
        video.set_output()
        process = subprocess.Popen(ffmpeg_cmd, stdin=subprocess.PIPE)
        video.output(process.stdin, y4m = True)
        process.communicate()

