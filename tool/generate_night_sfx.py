"""《수호알까기 · 탄지무림 심야기습》 전용 모션음·출두 풍악·기연/수련 효과음 생성기."""
import math
import os
import random
import struct
import wave

SAMPLE_RATE = 44100
OUT_DIR = r"D:\ttong_alkkagi_night\app\assets\sounds"


def save_wav(filename: str, samples: list[float]) -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, filename)
    peak = max((abs(s) for s in samples), default=1.0)
    scale = 0.88 / peak if peak > 0.88 else 1.0
    with wave.open(path, "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for s in samples:
            val = int(max(-1.0, min(1.0, s * scale)) * 32767)
            frames.extend(struct.pack("<h", val))
        wf.writeframes(bytes(frames))


def env_ad(t: float, attack: float, decay: float) -> float:
    if t < 0:
        return 0.0
    if t < attack:
        return t / max(attack, 1e-5)
    return math.exp(-(t - attack) / max(decay, 1e-4))


def gen_motion_gear() -> list[float]:
    """중앙 보호 장치 기어 회전·장전 모션음."""
    dur = 0.42
    n = int(SAMPLE_RATE * dur)
    rng = random.Random(101)
    out = [0.0] * n
    clicks = [0.02, 0.09, 0.16, 0.24, 0.33]
    for i in range(n):
        t = i / SAMPLE_RATE
        # 낮은 목재/철제 공명 회전음
        hum = 0.22 * math.sin(2 * math.pi * (118 + 30 * t) * t) * math.sin(math.pi * t / dur)
        val = hum
        for c in clicks:
            if t >= c:
                dt = t - c
                click_env = math.exp(-dt * 95.0)
                val += 0.52 * click_env * (
                    math.sin(2 * math.pi * 640 * dt)
                    + 0.45 * math.sin(2 * math.pi * 1420 * dt)
                    + 0.25 * (rng.random() * 2 - 1)
                )
        out[i] = val
    return out


def gen_motion_bow() -> list[float]:
    """길목 자동 알 발사대 활시위·태엽 탄성 발사 모션음."""
    dur = 0.30
    n = int(SAMPLE_RATE * dur)
    rng = random.Random(202)
    out = [0.0] * n
    for i in range(n):
        t = i / SAMPLE_RATE
        if t < 0.09:
            # 시위 당김 장력음
            f = 220 + 480 * (t / 0.09)
            out[i] = 0.28 * (t / 0.09) * math.sin(2 * math.pi * f * t)
        else:
            dt = t - 0.09
            # 핑! 탄성 발사 + 바람 가르는 소리
            twang = 0.65 * math.exp(-dt * 26.0) * math.sin(2 * math.pi * (390 - 110 * dt) * dt)
            whoosh = 0.32 * math.exp(-dt * 18.0) * (rng.random() * 2 - 1) * math.sin(math.pi * min(1.0, dt * 8))
            out[i] = twang + whoosh
    return out


def gen_motion_shield() -> list[float]:
    """외곽 기공 방어막 육각 결계 파동 공명 모션음."""
    dur = 0.55
    n = int(SAMPLE_RATE * dur)
    out = [0.0] * n
    for i in range(n):
        t = i / SAMPLE_RATE
        e = env_ad(t, 0.015, 0.20)
        f1 = 293.66 + 40 * math.exp(-t * 14)
        f2 = 440.00
        f3 = 587.33
        shimmer = 0.5 + 0.5 * math.sin(2 * math.pi * 16 * t)
        out[i] = e * (
            0.50 * math.sin(2 * math.pi * f1 * t)
            + 0.30 * shimmer * math.sin(2 * math.pi * f2 * t)
            + 0.22 * math.sin(2 * math.pi * f3 * t)
        )
    return out


def gen_motion_meridian() -> list[float]:
    """기명 심법 수련 단전 운기 & 경맥 개통 편경·옥종 울림 모션음."""
    dur = 0.78
    n = int(SAMPLE_RATE * dur)
    out = [0.0] * n
    notes = [(0.0, 523.25), (0.08, 659.25), (0.16, 783.99), (0.25, 1046.50)]
    for i in range(n):
        t = i / SAMPLE_RATE
        val = 0.0
        for start, freq in notes:
            if t >= start:
                dt = t - start
                e = env_ad(dt, 0.005, 0.28)
                # 편경 특유의 맑은 배음(1 : 2.01 : 2.98)
                val += e * (
                    0.42 * math.sin(2 * math.pi * freq * dt)
                    + 0.20 * math.sin(2 * math.pi * (freq * 2.008) * dt)
                    + 0.10 * math.sin(2 * math.pi * (freq * 2.99) * dt)
                )
        out[i] = val
    return out


def gen_motion_convoy() -> list[float]:
    """물자 호송 마차 도착 황동 방울 & 나무 바퀴 모션음."""
    dur = 0.72
    n = int(SAMPLE_RATE * dur)
    rng = random.Random(505)
    out = [0.0] * n
    bells = [0.02, 0.18, 0.34, 0.48]
    for i in range(n):
        t = i / SAMPLE_RATE
        rumble = 0.16 * math.sin(math.pi * t / dur) * (
            math.sin(2 * math.pi * 88 * t) + 0.35 * (rng.random() * 2 - 1)
        )
        val = rumble
        for b in bells:
            if t >= b:
                dt = t - b
                e = env_ad(dt, 0.003, 0.11)
                val += e * (
                    0.38 * math.sin(2 * math.pi * 1760 * dt)
                    + 0.24 * math.sin(2 * math.pi * 2637 * dt)
                )
        out[i] = val
    return out


def gen_chuldu_fanfare() -> list[float]:
    """암행어사 출두식 『무림수호단 출두야~~!!』 태평소·징·북 돌격 풍악."""
    dur = 1.65
    n = int(SAMPLE_RATE * dur)
    rng = random.Random(777)
    out = [0.0] * n
    # 국악 5음계 태평소 팡파르 선율 (레-미-솔-라-레'-라-레'~~)
    melody = [
        (0.05, 0.18, 587.33),
        (0.23, 0.15, 659.25),
        (0.38, 0.18, 783.99),
        (0.56, 0.22, 880.00),
        (0.78, 0.78, 1174.66),
    ]
    drums = [0.0, 0.22, 0.38, 0.56, 0.78, 0.98, 1.18, 1.36]
    for i in range(n):
        t = i / SAMPLE_RATE
        val = 0.0
        # 1) 첫 박과 절정 박의 웅장한 대징(징~~~!)
        for gong_t in (0.0, 0.78):
            if t >= gong_t:
                dt = t - gong_t
                ge = env_ad(dt, 0.01, 0.58)
                val += ge * (
                    0.34 * math.sin(2 * math.pi * 146.83 * dt)
                    + 0.22 * math.sin(2 * math.pi * 221.0 * dt)
                    + 0.16 * math.sin(2 * math.pi * 311.1 * dt)
                    + 0.08 * (rng.random() * 2 - 1) * math.exp(-dt * 12)
                )
        # 2) 북 & 기마 말발굽 질주 리듬
        for d_t in drums:
            if t >= d_t:
                dt = t - d_t
                de = math.exp(-dt * 28.0)
                val += 0.32 * de * math.sin(2 * math.pi * (115 - 40 * min(dt, 0.1)) * dt)
        # 3) 시원하게 뻗는 태평소 리드 음색(홀수·짝수 배음 풍부 + 농현 비브라토)
        for st, ln, fq in melody:
            if st <= t <= st + ln + 0.08:
                dt = t - st
                vib = 1.0 + (0.018 * math.sin(2 * math.pi * 7.5 * dt) if dt > 0.12 else 0.0)
                f = fq * vib
                me = min(1.0, dt / 0.015) * (1.0 if dt < ln else math.exp(-(dt - ln) * 22.0))
                reed = (
                    0.34 * math.sin(2 * math.pi * f * dt)
                    + 0.26 * math.sin(2 * math.pi * 2 * f * dt)
                    + 0.18 * math.sin(2 * math.pi * 3 * f * dt)
                    + 0.10 * math.sin(2 * math.pi * 4 * f * dt)
                )
                val += me * reed
        out[i] = val
    return out


def gen_dawn_purify() -> list[float]:
    """새벽 정화 승리 화음 (금빛 파동 + 논밭 소생 국악 화음)."""
    dur = 1.35
    n = int(SAMPLE_RATE * dur)
    out = [0.0] * n
    chord = [(0.0, 440.0), (0.12, 554.37), (0.24, 659.25), (0.36, 880.0), (0.50, 1108.73)]
    for i in range(n):
        t = i / SAMPLE_RATE
        val = 0.0
        for st, fq in chord:
            if t >= st:
                dt = t - st
                e = env_ad(dt, 0.02, 0.55)
                val += e * (
                    0.28 * math.sin(2 * math.pi * fq * dt)
                    + 0.12 * math.sin(2 * math.pi * 2 * fq * dt)
                )
        out[i] = val
    return out


def gen_pporok_fall() -> list[float]:
    """절벽 걸침 35% 추락 『뽀록!』 익살 휘파람 하강음 + 추락 쿵!"""
    dur = 0.62
    n = int(SAMPLE_RATE * dur)
    out = [0.0] * n
    for i in range(n):
        t = i / SAMPLE_RATE
        if t < 0.42:
            # 삐유우우웅~ 내려가는 익살 소리
            f = 1120 - 820 * (t / 0.42) ** 1.25
            wobble = 1.0 + 0.04 * math.sin(2 * math.pi * 18 * t)
            out[i] = 0.48 * math.sin(math.pi * t / 0.42) * math.sin(2 * math.pi * f * wobble * t)
        else:
            dt = t - 0.42
            out[i] = 0.72 * math.exp(-dt * 24.0) * math.sin(2 * math.pi * (125 - 50 * dt) * dt)
    return out


def gen_serendipity_jackpot() -> list[float]:
    """크리티컬 기연 & 한 번 더! 기연 발동 시 설레는 황금 옥구슬 팡파르."""
    dur = 0.85
    n = int(SAMPLE_RATE * dur)
    out = [0.0] * n
    arp = [(0.0, 587.33), (0.07, 739.99), (0.14, 880.0), (0.21, 1174.66), (0.30, 1479.98)]
    for i in range(n):
        t = i / SAMPLE_RATE
        val = 0.0
        for st, fq in arp:
            if t >= st:
                dt = t - st
                e = env_ad(dt, 0.004, 0.26)
                val += e * (
                    0.35 * math.sin(2 * math.pi * fq * dt)
                    + 0.18 * math.sin(2 * math.pi * 2 * fq * dt)
                )
        out[i] = val
    return out


def gen_village_warning() -> list[float]:
    """마을 방어막·식량창고 위기 야간 경종음."""
    dur = 0.58
    n = int(SAMPLE_RATE * dur)
    out = [0.0] * n
    for i in range(n):
        t = i / SAMPLE_RATE
        val = 0.0
        for st in (0.0, 0.24):
            if t >= st:
                dt = t - st
                e = env_ad(dt, 0.005, 0.16)
                val += e * (
                    0.46 * math.sin(2 * math.pi * 740.0 * dt)
                    + 0.28 * math.sin(2 * math.pi * 1118.0 * dt)
                )
        out[i] = val
    return out


def main() -> None:
    tasks = {
        "motion_gear.wav": gen_motion_gear(),
        "motion_bow.wav": gen_motion_bow(),
        "motion_shield.wav": gen_motion_shield(),
        "motion_meridian.wav": gen_motion_meridian(),
        "motion_convoy.wav": gen_motion_convoy(),
        "chuldu_fanfare.wav": gen_chuldu_fanfare(),
        "dawn_purify.wav": gen_dawn_purify(),
        "pporok_fall.wav": gen_pporok_fall(),
        "serendipity_jackpot.wav": gen_serendipity_jackpot(),
        "village_warning.wav": gen_village_warning(),
    }
    for name, buf in tasks.items():
        save_wav(name, buf)
        print(f"생성 완료: {name} ({len(buf) / SAMPLE_RATE:.2f}초)")


if __name__ == "__main__":
    main()
