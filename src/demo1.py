import subprocess
import pathlib

import vapoursynth as vs

INPUT_DIR = "../input"
OUTPUT_DIR = "../output"

OUT_EXT = ".mp4"

if __name__ == "__main__":
    input_dir_path = pathlib.Path(INPUT_DIR)
    output_dir_path = pathlib.Path(OUTPUT_DIR)

    file_path_list = [p for p in list(input_dir_path.glob("*")) if p.name not in [".gitkeep"]]

    for file_path in file_path_list:
        video = vs.core.bs.VideoSource(source=str(file_path))
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

