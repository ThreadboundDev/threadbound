from pathlib import Path
import subprocess

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "social_media" / "exports"
WORK = ROOT / ".codex_media" / "progress_short"
FFMPEG = Path(r"C:\Program Files\Krita (x64)\bin\ffmpeg.exe")
FONT = Path(r"C:\Windows\Fonts\arialbd.ttf")

OLD = Path(r"C:\Users\chase\Videos\Screen Recordings\Threadbound Devlog 1.mp4")
NEW = Path(r"C:\Users\chase\Videos\threadbound_develog_3.mp4")
TEST = Path(r"C:\Users\chase\Videos\Threadbound Test\Threabound_Test_1.avi")
ATTACK = Path(r"C:\Users\chase\Videos\Threadbound Test\Threabound_Test_movingattack.avi")
ATTACK_SINGLE = Path(
    r"C:\Users\chase\Videos\Threadbound Test\Threabound_Test_movingattack_single.avi"
)
MUSIC = ROOT / "Assets" / "Audio" / "Music" / "proto_weaver_fight.wav"


def text_overlay(filename: str, text: str, y: int, size: int = 76) -> Path:
    canvas = Image.new("RGBA", (1080, 1920), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.truetype(str(FONT), size)
    spacing = 12
    box = draw.multiline_textbbox((0, 0), text, font=font, spacing=spacing, align="center")
    width = box[2] - box[0]
    height = box[3] - box[1]
    x = (1080 - width) // 2
    padding_x, padding_y = 42, 26
    draw.rounded_rectangle(
        (x - padding_x, y - padding_y, x + width + padding_x, y + height + padding_y),
        radius=28,
        fill=(10, 8, 7, 205),
        outline=(193, 132, 54, 235),
        width=4,
    )
    draw.multiline_text(
        (540, y),
        text,
        font=font,
        fill=(246, 235, 213, 255),
        stroke_width=3,
        stroke_fill=(0, 0, 0, 240),
        spacing=spacing,
        anchor="ma",
        align="center",
    )
    path = WORK / filename
    canvas.save(path)
    return path


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    WORK.mkdir(parents=True, exist_ok=True)

    overlays = [
        text_overlay("hook.png", "2 YEARS OF\nNOT QUITTING.", 180, 82),
        text_overlay("then.png", "1.2 YEARS — ON & OFF", 1530, 70),
        text_overlay("stitching.png", "THEN 8 MONTHS OF FOCUS.", 1530, 65),
        text_overlay("combat.png", "NOW THE COMBAT MOVES.", 1530, 68),
        text_overlay("end.png", "THREADBOUND\nFOLLOW THE DEVLOG ON ITCH.IO", 1400, 62),
    ]

    clips = [
        (TEST, 1.0, 2.2),
        (OLD, 0.0, 2.5),
        (OLD, 44.0, 2.5),
        (OLD, 132.0, 2.5),
        (NEW, 68.0, 3.0),
        (NEW, 112.0, 3.0),
        (TEST, 3.2, 4.8),
        (ATTACK, 0.0, 2.0),
        (ATTACK_SINGLE, 0.0, 1.8),
        (NEW, 32.0, 2.5),
    ]

    cmd = [str(FFMPEG), "-y", "-hide_banner"]
    for source, start, duration in clips:
        cmd += ["-ss", str(start), "-t", str(duration), "-i", str(source)]
    for overlay in overlays:
        cmd += ["-loop", "1", "-i", str(overlay)]
    cmd += ["-ss", "14", "-i", str(MUSIC)]

    filters = []
    for index, (_, _, duration) in enumerate(clips):
        filters.append(
            f"[{index}:v]fps=30,trim=duration={duration},setpts=PTS-STARTPTS,"
            f"split[rawbg{index}][rawfg{index}]"
        )
        filters.append(
            f"[rawbg{index}]scale=1080:1920:force_original_aspect_ratio=increase,"
            f"crop=1080:1920,gblur=sigma=24[bg{index}]"
        )
        filters.append(
            f"[rawfg{index}]scale=1080:-2:force_original_aspect_ratio=decrease[fg{index}]"
        )
        filters.append(
            f"[bg{index}][fg{index}]overlay=(W-w)/2:(H-h)/2,"
            f"setsar=1,format=yuv420p[v{index}]"
        )
    filters.append(
        "".join(f"[v{i}]" for i in range(len(clips)))
        + f"concat=n={len(clips)}:v=1:a=0[base]"
    )
    filters += [
        "[10:v]format=rgba[txt0]",
        "[11:v]format=rgba[txt1]",
        "[12:v]format=rgba[txt2]",
        "[13:v]format=rgba[txt3]",
        "[14:v]format=rgba[txt4]",
        "[base][txt0]overlay=0:0:enable='between(t,0,2.2)'[o0]",
        "[o0][txt1]overlay=0:0:enable='between(t,2.2,9.7)'[o1]",
        "[o1][txt2]overlay=0:0:enable='between(t,9.7,15.7)'[o2]",
        "[o2][txt3]overlay=0:0:enable='between(t,15.7,24.3)'[o3]",
        "[o3][txt4]overlay=0:0:enable='between(t,24.3,26.8)',"
        "fade=t=in:st=0:d=0.25,fade=t=out:st=26.25:d=0.55[vout]",
        "[15:a]atrim=duration=26.8,asetpts=PTS-STARTPTS,"
        "volume=0.28,afade=t=in:st=0:d=0.5,afade=t=out:st=25.8:d=1[aout]",
    ]

    destination = OUT / "threadbound_progress_short_vertical.mp4"
    cmd += [
        "-filter_complex",
        ";".join(filters),
        "-map",
        "[vout]",
        "-map",
        "[aout]",
        "-c:v",
        "libopenh264",
        "-b:v",
        "8M",
        "-maxrate",
        "10M",
        "-bufsize",
        "16M",
        "-c:a",
        "aac",
        "-b:a",
        "192k",
        "-movflags",
        "+faststart",
        "-shortest",
        str(destination),
    ]
    subprocess.run(cmd, check=True)


if __name__ == "__main__":
    main()
