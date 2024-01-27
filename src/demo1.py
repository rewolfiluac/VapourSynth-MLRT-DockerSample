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

    core = vs.core
    for file_path in file_path_list:
        clip = core.bs.VideoSource(source=str(file_path))
        output_path = output_dir_path / f"{file_path.stem}{OUT_EXT}"
        x265_cmd = ["x265", 
                '--frames', f'{len(clip)}',
                '--y4m',
                '--input-depth', f'{clip.format.bits_per_sample}',
                '--output-depth', '10',
                '--input-res', f'{clip.width}x{clip.height}',
                '--fps', f'{clip.fps_num}/{clip.fps_den}',
                '--crf',    '23',
                '--output', str(output_path),
                '-']  
        # clip.set_output(index=0) 
        process = subprocess.Popen(x265_cmd, stdin=subprocess.PIPE)
        clip.output(process.stdin, y4m = True)
        process.communicate()
