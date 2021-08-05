import argparse
import math
import multiprocessing
import shutil
import os

parser = argparse.ArgumentParser(description="Frame Extraction")
parser.add_argument("--video_dir", type=str, required=True)
parser.add_argument("--num_processes", type=int, default=0)
args = parser.parse_args()
frame_dir = os.path.join(os.path.dirname(args.video_dir), 'frames')

def main(video_file, frame_rate=30, clip_start=900, clip_end=1800):
    video_path = os.path.join(args.video_dir, video_file)
    video_id = video_file.rsplit(".", 1)[0]
    frame_root = os.path.join(frame_dir, video_id)

    if os.path.isdir(frame_root) and len(os.listdir(frame_root)) != 27001:
        shutil.rmtree(frame_root)

    os.makedirs(frame_root, exist_ok=True)

    """EXTRACT FRAMES WITH FFMPEG"""
    try:
        frame_path = os.path.join(frame_root, "image_%06d.jpg")
        ffmpeg_command = f'ffmpeg -ss {clip_start} \
            -i {video_path} \
            -qscale:v 1 \
            -frames:v {math.ceil((clip_end - clip_start) * frame_rate + 1e-8)} \
            -vf "scale=-1:340,fps={frame_rate}" {frame_path} \
            -loglevel error < /dev/null'
        ret = os.system(ffmpeg_command)
        assert ret == 0, f"frame extraction failed with exit value {ret // 256}"
        print(f"[SUCCESS] ({video_file})", flush=True)
    except BaseException as e:
        print("[ERROR] ({}) {}".format(video_file, str(e).replace("\n", " ")), flush=True)


if __name__ == "__main__":
    videos = os.listdir(args.video_dir)

    if not args.num_processes:
        num_processes = multiprocessing.cpu_count()
    else: 
        num_processes = args.num_processes
    with multiprocessing.Pool(num_processes) as p:
        p.map(main, videos)
