#!/usr/bin/env python3
"""Build the full-length CC0 rhythm catalog and authored chart manifests."""

import argparse
import hashlib
import json
import pathlib
import subprocess

import numpy as np


ROOT = pathlib.Path(__file__).resolve().parents[1]
MUSIC_DIR = ROOT / "JiFeng_UpApp" / "Music"
CHART_DIR = MUSIC_DIR / "Charts"
LICENSE_DIR = MUSIC_DIR / "Licenses"
FFMPEG = pathlib.Path("/opt/homebrew/bin/ffmpeg")
SCHEMA = "jifeng-rhythm-chart-v1"
REVISION = "rhythm-v9-cc0-full-length-20260711"
TUTORIAL_REVISION = "rhythm-v10-repeatable-tutorial-20260714"
ANALYSIS_RATE = 22050
ANALYSIS_HOP = 256
TUTORIAL_AUDIO = "Rhythm_Tutorial.m4a"
TUTORIAL_SOURCE_AUDIO = "CC0_10_Extended.m4a"
TUTORIAL_DURATION = 67.2

PACK_1_PAGE = "https://opengameart.org/content/free-rhythm-game-music-pack-1"
PACK_2_PAGE = "https://opengameart.org/content/free-rhythm-game-music-pack-2"
CC0_URL = "https://creativecommons.org/publicdomain/zero/1.0/"


CC0_TRACKS = [
    {"source": "P1_01_Ascend.wav", "audio": "CC0_01_Ascend.m4a", "id": "cc0_ascend", "title": "Ascend", "bpm": 130, "page": PACK_1_PAGE, "url": "https://opengameart.org/sites/default/files/1_ascend.wav"},
    {"source": "P1_03_BowForMe.wav", "audio": "CC0_02_BowForMe.m4a", "id": "cc0_bow_for_me", "title": "Bow For Me", "bpm": 157, "page": PACK_1_PAGE, "url": "https://opengameart.org/sites/default/files/3_bow_for_me.wav"},
    {"source": "P1_05_FlyingTemple.wav", "audio": "CC0_03_FlyingTemple.m4a", "id": "cc0_flying_temple", "title": "Flying Temple", "bpm": 128, "page": PACK_1_PAGE, "url": "https://opengameart.org/sites/default/files/5_flying_temple.wav"},
    {"source": "P1_06_GloryDays.wav", "audio": "CC0_04_GloryDays.m4a", "id": "cc0_glory_days", "title": "Glory Days", "bpm": 184, "page": PACK_1_PAGE, "url": "https://opengameart.org/sites/default/files/6_glory_days.wav"},
    {"source": "P1_07_LostUtopia.wav", "audio": "CC0_05_LostUtopia.m4a", "id": "cc0_lost_utopia", "title": "Lost Utopia", "bpm": 127, "page": PACK_1_PAGE, "url": "https://opengameart.org/sites/default/files/7_lost_utopia.wav"},
    {"source": "P1_10_Psychic.wav", "audio": "CC0_06_Psychic.m4a", "id": "cc0_psychic", "title": "Psychic", "bpm": 190, "page": PACK_1_PAGE, "url": "https://opengameart.org/sites/default/files/10_psychic.wav"},
    {"source": "P2_01_Stomper.wav", "audio": "CC0_07_Stomper.m4a", "id": "cc0_stomper", "title": "Stomper", "bpm": 160, "page": PACK_2_PAGE, "url": "https://opengameart.org/sites/default/files/1_stomper.wav"},
    {"source": "P2_02_Drama.wav", "audio": "CC0_08_Drama.m4a", "id": "cc0_drama", "title": "Drama", "bpm": 130, "page": PACK_2_PAGE, "url": "https://opengameart.org/sites/default/files/2_drama.wav"},
    {"source": "P2_03_MentalCorruption.wav", "audio": "CC0_09_MentalCorruption.m4a", "id": "cc0_mental_corruption", "title": "Mental Corruption", "bpm": 150, "page": PACK_2_PAGE, "url": "https://opengameart.org/sites/default/files/3_mental_corruption.wav"},
    {"source": "P2_05_Extended.wav", "audio": "CC0_10_Extended.m4a", "id": "cc0_extended", "title": "Extended", "bpm": 120, "page": PACK_2_PAGE, "url": "https://opengameart.org/sites/default/files/5_extended.wav"},
    {"source": "P2_07_TOE.wav", "audio": "CC0_11_TOE.m4a", "id": "cc0_toe", "title": "T.O.E.", "bpm": 120, "page": PACK_2_PAGE, "url": "https://opengameart.org/sites/default/files/7_t.o.e.wav"},
    {"source": "P2_08_RippedApart.wav", "audio": "CC0_12_RippedApart.m4a", "id": "cc0_ripped_apart", "title": "Ripped Apart", "bpm": 174, "page": PACK_2_PAGE, "url": "https://opengameart.org/sites/default/files/8_ripped_apart.wav"},
    {"source": "P2_09_ZenDevils.wav", "audio": "CC0_13_ZenDevils.m4a", "id": "cc0_zen_devils", "title": "Zen Devils", "bpm": 205, "page": PACK_2_PAGE, "url": "https://opengameart.org/sites/default/files/9_zen_devils.wav"},
    {"source": "P2_10_WhatsCooking.wav", "audio": "CC0_14_WhatsCooking.m4a", "id": "cc0_whats_cooking", "title": "What's Cooking?", "bpm": 190, "page": PACK_2_PAGE, "url": "https://opengameart.org/sites/default/files/10_whats_cooking.wav"},
]

EXPECTED_SOURCE_SHA256 = {
    "P1_01_Ascend.wav": "99b7a35e32d760cb3b7d5b1b66801be25a0650b35ad5ff43654b73d086b8a012",
    "P1_03_BowForMe.wav": "fd67080f79aa23f00318ed4506bb98b77851421a4101b9f80c416d927fdb103b",
    "P1_05_FlyingTemple.wav": "186937fc33649f4406e49ddb633d6cda5f253de9ef5996ffb8dbb6850d8506c6",
    "P1_06_GloryDays.wav": "665f2266a5bef60cb07f9df1272231997b88d224e835828b1dd53b7d6039cea0",
    "P1_07_LostUtopia.wav": "013c84557e8ed146a9dc7b2f7b06a9f333a377e99831194bce3f2c643f697ece",
    "P1_10_Psychic.wav": "65d4c44511bb4841a0a56d36140912f73dd948063c3dfbf50c61aa77aa3959a7",
    "P2_01_Stomper.wav": "60994665d76e6f6cd265c192d480b90900576d863a66b9ae46410be49256a763",
    "P2_02_Drama.wav": "f48e8a9222556e5d028e3bf80dca649b2315b198e5ad93ae5cce269118aa013f",
    "P2_03_MentalCorruption.wav": "70dc0e3f36c1dfd14cd7fc68f04dd9f9fbeabbef7ee09d09ad76b703a3cae479",
    "P2_05_Extended.wav": "e71d83f5dba0187618354847fb86ae0f497d1016d1c7ac566a96b5325b75c5e1",
    "P2_07_TOE.wav": "8c4033f4a17de2a19ccdd25e0c2bd95e885912592f2324c474c7384c83cb9b83",
    "P2_08_RippedApart.wav": "cb99224897c22ff6a5b33f6c847ba95ae18c835fa19c076e3e65448cafd14dc7",
    "P2_09_ZenDevils.wav": "aa5d35eddb291e011b84851a3d16d0c4f825cad33d28191ebca376b0d8cb6a95",
    "P2_10_WhatsCooking.wav": "34caa3b962a45cd68488de981c58dd588f469ebd43570e82aa8a90a1cae65566",
}


LANE_PATTERNS = [
    (0, 1, 2, 3, 2, 1, 0, 2, 3, 1, 2, 0, 1, 3, 2, 1),
    (1, 0, 2, 1, 3, 2, 0, 3, 1, 2, 3, 0, 2, 1, 0, 3),
    (0, 2, 1, 3, 1, 2, 0, 1, 3, 2, 1, 0, 2, 3, 1, 2),
    (3, 2, 0, 1, 2, 3, 1, 0, 2, 1, 3, 2, 0, 1, 2, 3),
    (0, 3, 1, 2, 0, 2, 1, 3, 2, 0, 3, 1, 0, 2, 3, 1),
    (1, 2, 0, 3, 2, 1, 3, 0, 1, 3, 2, 0, 2, 1, 0, 3),
    (0, 1, 3, 2, 1, 0, 2, 3, 0, 2, 1, 3, 2, 0, 3, 1),
    (3, 1, 2, 0, 1, 3, 0, 2, 3, 2, 1, 0, 2, 0, 1, 3),
    (1, 3, 2, 0, 2, 1, 0, 3, 1, 2, 0, 3, 2, 1, 3, 0),
    (0, 2, 3, 1, 0, 3, 2, 1, 2, 0, 1, 3, 0, 2, 1, 3),
    (2, 1, 0, 3, 1, 2, 3, 0, 2, 0, 1, 3, 2, 1, 3, 0),
    (0, 3, 2, 1, 3, 0, 1, 2, 0, 2, 3, 1, 2, 0, 1, 3),
    (1, 0, 3, 2, 0, 1, 2, 3, 1, 3, 0, 2, 3, 1, 2, 0),
    (3, 0, 2, 1, 3, 1, 0, 2, 1, 3, 2, 0, 3, 0, 1, 2),
]


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def note_event(time, lane, level, strength, note_type="tap", duration=0.0, end_lane=None):
    event = {
        "t": round(float(time), 5),
        "lane": int(lane),
        "level": int(level),
        "strength": round(float(np.clip(strength, 0.25, 1.0)), 3),
        "type": note_type,
    }
    if note_type != "tap":
        event["duration"] = round(float(duration), 5)
    if note_type == "slide":
        event["endLane"] = int(end_lane)
    return event


def decode_audio(path):
    command = [
        str(FFMPEG), "-v", "error", "-i", str(path), "-f", "f32le",
        "-acodec", "pcm_f32le", "-ac", "1", "-ar", str(ANALYSIS_RATE), "-",
    ]
    completed = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
    audio = np.frombuffer(completed.stdout, dtype="<f4").copy()
    return np.clip(np.nan_to_num(audio), -4.0, 4.0)


def analyze_features(audio):
    n_fft = 1024
    count = 1 + (len(audio) - n_fft) // ANALYSIS_HOP
    if count <= 2:
        raise RuntimeError("audio is too short to analyze")
    frames = np.lib.stride_tricks.as_strided(
        audio,
        shape=(count, n_fft),
        strides=(audio.strides[0] * ANALYSIS_HOP, audio.strides[0]),
        writeable=False,
    )
    windowed = frames * np.hanning(n_fft).astype(np.float32)[None, :]
    spectrum = np.abs(np.fft.rfft(windowed, axis=1)).astype(np.float32)
    magnitude = np.log1p(spectrum * 10.0)
    difference = np.maximum(0.0, np.diff(magnitude, axis=0, prepend=magnitude[:1]))
    frequencies = np.fft.rfftfreq(n_fft, 1.0 / ANALYSIS_RATE)
    ranges = ((35, 180), (180, 700), (700, 2200), (2200, 9000))
    bands = np.column_stack([
        difference[:, (frequencies >= low) & (frequencies < high)].mean(axis=1)
        for low, high in ranges
    ])
    bands = np.clip(np.nan_to_num(bands), 0, 100)
    onset = bands[:, 0] * 1.36 + bands[:, 1] * 1.04 + bands[:, 2] * 0.90 + bands[:, 3] * 0.72
    onset = np.convolve(onset, np.array([0.16, 0.68, 0.16]), mode="same")
    fps = ANALYSIS_RATE / ANALYSIS_HOP
    local_count = max(8, int(fps * 0.72))
    local_mean = np.convolve(onset, np.ones(local_count) / local_count, mode="same")
    onset = np.maximum(0.0, onset - local_mean * 0.68)
    onset_scale = np.percentile(onset, 98.5) or 1.0
    onset = np.clip(onset / onset_scale, 0, 2.0)
    rms = np.sqrt(np.mean(frames * frames, axis=1) + 1e-9)
    rms = np.clip(rms / (np.percentile(rms, 95) or 1.0), 0, 2.0)
    low = bands[:, 0]
    low = np.clip(low / (np.percentile(low, 97) or 1.0), 0, 2.0)
    return onset.astype(np.float32), rms.astype(np.float32), low.astype(np.float32), fps


def sample_peak(values, fps, time, radius=0.045):
    center = int(round(time * fps))
    spread = max(1, int(radius * fps))
    first = max(0, center - spread)
    last = min(len(values), center + spread + 1)
    return float(values[first:last].max()) if first < last else 0.0


def sample_mean(values, fps, first_time, last_time):
    first = max(0, int(first_time * fps))
    last = min(len(values), max(first + 1, int(last_time * fps)))
    return float(values[first:last].mean()) if first < last else 0.0


def detect_grid(onset, rms, low, fps, reported_bpm, duration):
    pulse = onset + low * 0.44

    def phase_score(phase, beat):
        times = np.arange(phase, duration - 0.4, beat)
        indices = np.clip(np.rint(times * fps).astype(int), 0, len(pulse) - 1)
        active = rms[indices] > 0.07
        values = pulse[indices][active]
        if len(values) < 8:
            return -1.0
        segment_scores = []
        for segment in np.array_split(values, 4):
            if len(segment):
                segment_scores.append(float(segment.mean() * 0.58 + np.percentile(segment, 75) * 0.42))
        return float(np.mean(segment_scores) - np.std(segment_scores) * 0.08)

    def best_phase(bpm, phase_step):
        beat_value = 60.0 / bpm
        phases = np.arange(0.0, beat_value, phase_step)
        phase_value = float(max(phases, key=lambda value: phase_score(value, beat_value)))
        return phase_value, phase_score(phase_value, beat_value)

    # The source page publishes integer BPM values. Search only in a narrow
    # neighborhood to remove long-song drift without accidentally locking to a
    # harmonically related tempo.
    coarse_bpms = np.arange(reported_bpm - 0.8, reported_bpm + 0.8001, 0.04)
    coarse_results = [(float(bpm),) + best_phase(float(bpm), 0.004) for bpm in coarse_bpms]
    bpm, phase, _ = max(coarse_results, key=lambda item: item[2])
    fine_bpms = np.arange(bpm - 0.06, bpm + 0.0601, 0.005)
    fine_results = [(float(value),) + best_phase(float(value), 0.001) for value in fine_bpms]
    bpm, phase, _ = max(fine_results, key=lambda item: item[2])
    beat = 60.0 / bpm
    phases = np.arange(phase - 0.003, phase + 0.0031, 0.00025)
    phase = float(max(phases, key=lambda value: phase_score(value % beat, beat)) % beat)

    beats = np.arange(phase, duration - 0.2, beat)
    active_index = 0
    for index, time in enumerate(beats[:-4]):
        energy = sample_mean(rms, fps, time, time + beat * 4)
        accent = max(sample_peak(onset, fps, time + offset * beat) for offset in range(4))
        if time >= 0.35 and energy > 0.075 and accent > 0.16:
            active_index = index
            break

    rotations = []
    for rotation in range(4):
        values = [
            sample_peak(low, fps, beats[index]) + sample_peak(onset, fps, beats[index]) * 0.25
            for index in range(active_index + rotation, len(beats), 4)
        ]
        rotations.append(float(np.percentile(values, 70)) if values else 0.0)
    rotation = int(np.argmax(rotations))
    while active_index % 4 != rotation and active_index < len(beats) - 1:
        active_index += 1
    return float(beats[active_index]), beat, float(bpm)


def fill_positions(base, candidates, target, scores, salt):
    selected = list(dict.fromkeys(base))
    pool = [position for position in candidates if position not in selected]
    while len(selected) < target and pool:
        best = max(
            pool,
            key=lambda position: (
                scores[position] + (0.055 * min(abs(position - old) for old in selected) if selected else 0),
                ((position * 7 + salt * 5) % 19) / 1000.0,
            ),
        )
        selected.append(best)
        pool.remove(best)
    return sorted(selected)


def note_at_time(notes, time, tolerance=0.012):
    matches = [note for note in notes if abs(note["t"] - time) <= tolerance]
    return min(matches, key=lambda note: (note["level"], note["lane"])) if matches else None


def free_lane_at(notes, time, preferred, blocked=None):
    occupied = {note["lane"] for note in notes if abs(note["t"] - time) <= 0.012}
    blocked = set(blocked or ())
    order = (preferred, (preferred + 1) % 4, (preferred + 3) % 4, (preferred + 2) % 4)
    return next((lane for lane in order if lane not in occupied and lane not in blocked), preferred)


def dedupe_and_clean(notes, duration):
    priority = {"tap": 0, "slide": 1, "hold": 2}
    by_key = {}
    for note in notes:
        if note["t"] < 0.2 or note["t"] + note.get("duration", 0) >= duration - 0.16:
            continue
        key = (round(note["t"], 4), note["lane"])
        old = by_key.get(key)
        if old is None:
            by_key[key] = note
        elif priority[note["type"]] > priority[old["type"]]:
            note["level"] = min(note["level"], old["level"])
            by_key[key] = note
        else:
            old["level"] = min(old["level"], note["level"])
            old["strength"] = max(old["strength"], note["strength"])
    result = sorted(by_key.values(), key=lambda item: (item["t"], item["lane"], item["level"]))
    return result


def build_chart(track, audio_path, order):
    audio = decode_audio(audio_path)
    duration = len(audio) / ANALYSIS_RATE
    onset, rms, low, fps = analyze_features(audio)
    grid_start, beat, calibrated_bpm = detect_grid(onset, rms, low, fps, float(track["bpm"]), duration)
    bar_duration = beat * 4
    bar_count = max(0, int((duration - 0.3 - grid_start) // bar_duration))
    if bar_count < 12:
        raise RuntimeError(f"not enough playable bars in {track['title']}")

    bar_energies = []
    for bar in range(bar_count):
        start = grid_start + bar * bar_duration
        energy = sample_mean(rms, fps, start, start + bar_duration)
        accents = np.mean([sample_peak(onset, fps, start + position * beat / 4) for position in range(16)])
        bar_energies.append(energy * 0.58 + accents * 0.42)
    low_energy = float(np.percentile(bar_energies, 22))
    high_energy = float(np.percentile(bar_energies, 82))
    energy_span = max(0.08, high_energy - low_energy)

    notes = []
    pattern = LANE_PATTERNS[(order - 6) % len(LANE_PATTERNS)]
    cursor = (order - 6) * 3
    for bar in range(bar_count):
        start = grid_start + bar * bar_duration
        energy = (bar_energies[bar] - low_energy) / energy_span
        energy = float(np.clip(energy, 0, 1.25))
        edge = bar < 2 or bar >= bar_count - 2
        if sample_mean(rms, fps, start, start + bar_duration) < 0.035:
            continue

        scores = {}
        for position in range(16):
            time = start + position * beat / 4
            accent = sample_peak(onset, fps, time)
            bass = sample_peak(low, fps, time)
            pulse_bias = 0.12 if position % 4 == 0 else (0.055 if position % 2 == 0 else 0.0)
            scores[position] = accent * 0.66 + bass * 0.18 + energy * 0.12 + pulse_bias

        if track["bpm"] >= 180:
            easy_target, medium_target, hard_target = 3, 5, 8
        elif track["bpm"] >= 155:
            easy_target, medium_target, hard_target = 3, 6, 9
        else:
            easy_target, medium_target, hard_target = 4, 7, 10
        if energy < 0.30:
            easy_target = max(2, easy_target - 1)
            medium_target = max(easy_target + 1, medium_target - 2)
            hard_target = max(medium_target + 1, hard_target - 2)
        elif energy > 0.88 and track["bpm"] < 180:
            hard_target += 1
        if edge:
            easy_target = max(2, easy_target - 1)
            medium_target = max(easy_target + 1, medium_target - 1)
            hard_target = max(medium_target + 1, hard_target - 2)

        quarters = [0, 4, 8, 12]
        easy = sorted(quarters, key=lambda position: scores[position], reverse=True)[:easy_target]
        easy = sorted(easy)
        eighths = list(range(0, 16, 2))
        medium = fill_positions(easy, eighths, medium_target, scores, bar + order)
        hard = fill_positions(medium, list(range(16)), hard_target, scores, bar * 3 + order)
        level_by_position = {position: 2 for position in hard}
        level_by_position.update({position: 1 for position in medium})
        level_by_position.update({position: 0 for position in easy})

        for position in sorted(level_by_position):
            level = level_by_position[position]
            lane = pattern[(cursor + bar + position // 2) % len(pattern)]
            if len(notes) >= 2 and notes[-1]["lane"] == lane and notes[-2]["lane"] == lane:
                lane = (lane + 1 + order % 2) % 4
            strength = min(1.0, 0.46 + scores[position] * 0.42)
            notes.append(note_event(start + position * beat / 4, lane, level, strength))
            cursor += 1

    # Sliding gestures mark eight-bar phrase endings.
    slide_index = 0
    for bar in range(7, bar_count - 2, 8):
        time = grid_start + bar * bar_duration + beat * 3
        action = note_at_time(notes, time)
        if action is None:
            lane = pattern[(bar * 5 + order) % len(pattern)]
            action = note_event(time, lane, 1, 0.92)
            notes.append(action)
        action["type"] = "slide"
        action["duration"] = round(beat * 0.75, 5)
        action["endLane"] = 3 - action["lane"]
        action["level"] = min(action["level"], 0 if slide_index == 0 else 1)
        action["strength"] = 0.95
        slide_index += 1

    # Holds are placed in the calmer bar of each twelve-bar window.
    hold_index = 0
    for window_start in range(10, bar_count - 3, 12):
        candidates = range(window_start, min(window_start + 4, bar_count - 2))
        bar = min(candidates, key=lambda index: bar_energies[index])
        time = grid_start + bar * bar_duration + beat * 2
        action = note_at_time(notes, time)
        if action is None:
            lane = pattern[(bar * 3 + order) % len(pattern)]
            action = note_event(time, lane, 1, 0.90)
            notes.append(action)
        action["type"] = "hold"
        action["duration"] = round(beat * (2.5 if track["bpm"] < 180 else 3.0), 5)
        action["level"] = min(action["level"], 0 if hold_index == 0 else 1)
        action["strength"] = 0.96
        hold_index += 1

    # High-energy downbeats get intentional two-finger chords.
    for bar in range(8, bar_count - 2, 8):
        if bar_energies[bar] < high_energy:
            continue
        time = grid_start + bar * bar_duration
        anchor = note_at_time(notes, time)
        if anchor is None or anchor["type"] != "tap":
            continue
        lane = free_lane_at(notes, time, 3 - anchor["lane"])
        if lane != anchor["lane"]:
            notes.append(note_event(time, lane, 1, 0.98))

    # Reserve held lanes by moving conflicts to a free lane at that instant.
    holds = [note for note in notes if note["type"] == "hold"]
    for hold in holds:
        hold_end = hold["t"] + hold["duration"]
        for note in notes:
            if note is hold or note["lane"] != hold["lane"]:
                continue
            if not hold["t"] + 0.04 < note["t"] < hold_end - 0.04:
                continue
            blocked = {
                other["lane"] for other in holds
                if other is not hold and other["t"] <= note["t"] <= other["t"] + other["duration"]
            }
            note["lane"] = free_lane_at(notes, note["t"], (note["lane"] + 1) % 4, blocked)
            if note["type"] == "slide" and note["endLane"] == note["lane"]:
                note["endLane"] = (note["lane"] + 2) % 4

    notes = dedupe_and_clean(notes, duration)
    return {
        "schema": SCHEMA,
        "revision": REVISION,
        "id": track["id"],
        "order": order,
        "audio": track["audio"],
        "title": track["title"],
        "artist": "Tricks & Traps",
        "bpm": round(calibrated_bpm, 3),
        "reportedBpm": float(track["bpm"]),
        "offset": round(grid_start, 5),
        "duration": round(duration, 5),
        "license": {
            "spdx": "CC0-1.0",
            "creator": "Tricks & Traps",
            "sourcePage": track["page"],
            "sourceFile": track["url"],
        },
        "notes": notes,
    }


def transcode(source, destination, track):
    destination.parent.mkdir(parents=True, exist_ok=True)
    command = [
        str(FFMPEG), "-y", "-v", "error", "-i", str(source),
        "-af", "loudnorm=I=-16:TP=-1.5:LRA=11",
        "-c:a", "aac", "-b:a", "160k", "-ar", "44100", "-movflags", "+faststart",
        "-metadata", f"title={track['title']}",
        "-metadata", "artist=Tricks & Traps",
        "-metadata", "copyright=CC0 1.0 Universal",
        str(destination),
    ]
    subprocess.run(command, check=True)


def build_tutorial_notes():
    notes = []

    def tap(time, lane, strength=0.82):
        notes.append(note_event(time, lane, 0, strength))

    # 先用整拍认识四条轨道。
    for index, lane in enumerate((0, 1, 2, 3, 3, 2, 1, 0, 1, 2)):
        tap(5.993 + index, lane, 0.78 if index < 4 else 0.86)

    # 半拍交替，练习视线与手指换轨。
    switch_pattern = (0, 3, 1, 2, 0, 2, 1, 3, 0, 1, 3, 2, 0, 3, 2, 1, 0, 2)
    for index, lane in enumerate(switch_pattern):
        tap(15.993 + index * 0.5, lane, 0.78 + (index % 4) * 0.045)

    # 长按之间留出明确空拍，让新手可以完整看懂头尾。
    notes.extend([
        note_event(25.993, 0, 0, 0.94, "hold", 2.0, 0),
        note_event(28.493, 3, 0, 0.82),
        note_event(29.993, 2, 0, 0.96, "hold", 2.0, 2),
        note_event(32.493, 0, 0, 0.84),
        note_event(33.993, 1, 0, 0.98, "hold", 2.0, 1),
        note_event(36.493, 3, 0, 0.86),
    ])

    # 三种方向的滑动，起点与终点都不重复。
    notes.extend([
        note_event(38.993, 0, 0, 0.98, "slide", 1.0, 3),
        note_event(42.993, 3, 0, 0.98, "slide", 1.0, 1),
        note_event(46.993, 1, 0, 0.98, "slide", 1.0, 2),
    ])

    # 双押只使用两颗同拍音符，和现有多指判定规则保持一致。
    for time, lanes in (
        (50.993, (0, 3)), (52.993, (1, 2)), (54.993, (0, 2)),
        (56.993, (1, 3)), (58.493, (0, 3)),
    ):
        for lane in lanes:
            tap(time, lane, 0.96)

    # 最后八秒混合前面动作，仍保持新手可读的密度。
    for time, lane in ((59.993, 0), (60.493, 1), (60.993, 2), (61.493, 3)):
        tap(time, lane, 0.88)
    notes.extend([
        note_event(61.993, 0, 0, 0.98, "hold", 1.5, 0),
        note_event(62.993, 3, 0, 0.90),
        note_event(63.993, 3, 0, 0.98, "slide", 1.0, 1),
        note_event(65.493, 0, 0, 0.98),
        note_event(65.493, 2, 0, 0.98),
    ])
    return sorted(notes, key=lambda note: (note["t"], note["lane"]))


def build_tutorial():
    source = MUSIC_DIR / TUTORIAL_SOURCE_AUDIO
    destination = MUSIC_DIR / TUTORIAL_AUDIO
    if not source.exists():
        raise FileNotFoundError(f"missing tutorial source audio: {source}")
    command = [
        str(FFMPEG), "-y", "-v", "error", "-i", str(source), "-t", str(TUTORIAL_DURATION),
        "-c:a", "copy", "-movflags", "+faststart",
        "-metadata", "title=新手训练",
        "-metadata", "artist=JiFeng / Tricks & Traps",
        "-metadata", "copyright=CC0 1.0 Universal",
        str(destination),
    ]
    subprocess.run(command, check=True)
    duration = len(decode_audio(destination)) / ANALYSIS_RATE
    manifest = {
        "schema": SCHEMA,
        "revision": TUTORIAL_REVISION,
        "id": "rhythm_tutorial",
        "order": -100,
        "audio": TUTORIAL_AUDIO,
        "title": "新手训练",
        "artist": "JiFeng Training / Tricks & Traps",
        "bpm": 120.0,
        "offset": 1.993,
        "duration": round(duration, 5),
        "tutorial": True,
        "tutorialSteps": [
            {"from": 0.0, "to": 5.3, "title": "先看判定线", "detail": "音符落到下方发光线时，再按对应轨道", "icon": "sparkles"},
            {"from": 5.3, "to": 15.3, "title": "点按", "detail": "跟随单颗音符，轻点下方被指示的轨道", "icon": "hand.tap.fill"},
            {"from": 15.3, "to": 25.3, "title": "连续换轨", "detail": "视线看判定线，左右手跟着颜色移动", "icon": "arrow.left.and.right"},
            {"from": 25.3, "to": 38.3, "title": "长按", "detail": "按住长条头部，直到尾端经过判定线再松手", "icon": "hand.point.up.left.fill"},
            {"from": 38.3, "to": 49.8, "title": "滑动", "detail": "按住箭头起点，沿方向滑到目标轨道", "icon": "arrow.right.circle.fill"},
            {"from": 49.8, "to": 59.5, "title": "双押", "detail": "两颗音符同时到线时，用两根手指一起按", "icon": "rectangle.split.2x1.fill"},
            {"from": 59.5, "to": round(duration, 5), "title": "综合练习", "detail": "把点按、长按、滑动和双押连起来", "icon": "flag.checkered"},
        ],
        "license": {
            "spdx": "CC0-1.0",
            "creator": "Tricks & Traps",
            "sourcePage": PACK_2_PAGE,
            "sourceFile": "https://opengameart.org/sites/default/files/5_extended.wav",
            "derivedFromBundledFile": TUTORIAL_SOURCE_AUDIO,
        },
        "notes": build_tutorial_notes(),
    }
    CHART_DIR.mkdir(parents=True, exist_ok=True)
    manifest_path = CHART_DIR / "tutorial_00_newcomer_training.json"
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    ledger_path = LICENSE_DIR / "cc0_rhythm_tracks.json"
    if ledger_path.exists():
        ledger = json.loads(ledger_path.read_text(encoding="utf-8"))
        ledger["derivatives"] = [{
            "title": "新手训练",
            "creator": "JiFeng / Tricks & Traps",
            "license": "CC0-1.0",
            "sourceTitle": "Extended",
            "sourcePage": PACK_2_PAGE,
            "sourceBundledFileName": TUTORIAL_SOURCE_AUDIO,
            "operation": "First 67.2 seconds excerpted for a repeatable tutorial chart",
            "bundledFileName": TUTORIAL_AUDIO,
            "bundledSha256": sha256(destination),
        }]
        ledger_path.write_text(json.dumps(ledger, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"新手训练: {duration:.1f}s 120 BPM notes={len(manifest['notes'])} guidedSteps={len(manifest['tutorialSteps'])}")


def write_manifest(index, manifest):
    CHART_DIR.mkdir(parents=True, exist_ok=True)
    path = CHART_DIR / f"cc0_{index + 1:02d}_{manifest['id']}.json"
    path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    counts = [sum(1 for note in manifest["notes"] if note["level"] <= level) for level in range(3)]
    actions = sum(1 for note in manifest["notes"] if note["type"] != "tap")
    print(f"{manifest['title']}: {manifest['duration']:.1f}s {manifest['bpm']:.0f} BPM notes={counts} actions={actions}")


def build_cc0(source_dir):
    ledger_tracks = []
    for index, track in enumerate(CC0_TRACKS):
        source = source_dir / track["source"]
        if not source.exists():
            raise FileNotFoundError(f"missing CC0 source: {source}")
        source_hash = sha256(source)
        if source_hash != EXPECTED_SOURCE_SHA256[track["source"]]:
            raise RuntimeError(f"CC0 source hash changed: {source}")
        destination = MUSIC_DIR / track["audio"]
        transcode(source, destination, track)
        manifest = build_chart(track, destination, 6 + index)
        write_manifest(index, manifest)
        ledger_tracks.append({
            "title": track["title"],
            "creator": "Tricks & Traps",
            "license": "CC0-1.0",
            "sourcePage": track["page"],
            "sourceFile": track["url"],
            "sourceFileName": track["source"],
            "sourceSha256": source_hash,
            "bundledFileName": track["audio"],
            "bundledSha256": sha256(destination),
        })
    LICENSE_DIR.mkdir(parents=True, exist_ok=True)
    ledger = {
        "retrievedAt": "2026-07-11",
        "license": "CC0-1.0",
        "licenseUrl": CC0_URL,
        "tracks": ledger_tracks,
    }
    (LICENSE_DIR / "cc0_rhythm_tracks.json").write_text(
        json.dumps(ledger, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


def validate_catalog():
    manifests = []
    for path in sorted(CHART_DIR.glob("*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        if data.get("schema") == SCHEMA:
            manifests.append(data)
    audio_files = {
        path.name for path in MUSIC_DIR.iterdir()
        if path.suffix.lower() in {".mp3", ".m4a", ".wav", ".aac", ".caf"}
    }
    ids = {item["id"] for item in manifests}
    linked = {item["audio"] for item in manifests}
    if len(manifests) != 21 or len(ids) != 21:
        raise RuntimeError(f"expected 21 unique manifests, got manifests={len(manifests)} ids={len(ids)}")
    if linked != audio_files:
        raise RuntimeError(f"chart/audio mismatch: noChart={sorted(audio_files - linked)} noAudio={sorted(linked - audio_files)}")

    for item in manifests:
        duration = float(item["duration"])
        if item["id"].startswith("cc0_") and duration < 120:
            raise RuntimeError(f"CC0 song is unexpectedly short: {item['title']} {duration:.1f}s")
        for difficulty in range(3):
            chart = sorted(
                (note for note in item["notes"] if note["level"] <= difficulty),
                key=lambda note: (note["t"], note["lane"]),
            )
            if len(chart) < 20:
                raise RuntimeError(f"chart too sparse: {item['title']} difficulty={difficulty}")
            keys = [(round(float(note["t"]), 4), int(note["lane"])) for note in chart]
            if len(keys) != len(set(keys)):
                raise RuntimeError(f"duplicate lane/time: {item['title']} difficulty={difficulty}")
            chord_sizes = {}
            for note in chart:
                chord_sizes[round(float(note["t"]), 4)] = chord_sizes.get(round(float(note["t"]), 4), 0) + 1
                end = float(note["t"]) + float(note.get("duration", 0))
                if float(note["t"]) < 0.2 or end >= duration - 0.14:
                    raise RuntimeError(f"note outside audio: {item['title']} {note}")
                if note["type"] == "slide" and note.get("endLane") == note["lane"]:
                    raise RuntimeError(f"slide does not move: {item['title']} {note}")
            if max(chord_sizes.values()) > 2:
                raise RuntimeError(f"oversized chord: {item['title']} difficulty={difficulty}")
            for hold in (note for note in chart if note["type"] == "hold"):
                hold_end = hold["t"] + hold["duration"]
                if any(
                    note is not hold and note["lane"] == hold["lane"]
                    and hold["t"] + 0.04 < note["t"] < hold_end - 0.04
                    for note in chart
                ):
                    raise RuntimeError(f"hold lane conflict: {item['title']} difficulty={difficulty}")
            times = [float(note["t"]) for note in chart]
            left = 0
            density_limit = (6, 9, 12)[difficulty]
            for right, time in enumerate(times):
                while time - times[left] >= 1.0:
                    left += 1
                if right - left + 1 > density_limit:
                    raise RuntimeError(f"chart burst too dense: {item['title']} difficulty={difficulty} at={time:.3f}")

    tutorials = [item for item in manifests if item.get("tutorial") is True]
    if len(tutorials) != 1:
        raise RuntimeError(f"expected one tutorial chart, got {len(tutorials)}")
    tutorial = tutorials[0]
    if len(tutorial.get("tutorialSteps", [])) < 6:
        raise RuntimeError("tutorial must contain staged hints")
    note_types = {note["type"] for note in tutorial["notes"]}
    if note_types != {"tap", "hold", "slide"}:
        raise RuntimeError(f"tutorial actions incomplete: {sorted(note_types)}")
    chord_times = {}
    for note in tutorial["notes"]:
        chord_times[note["t"]] = chord_times.get(note["t"], 0) + 1
        if note["level"] != 0:
            raise RuntimeError("tutorial notes must be available at every difficulty")
    if max(chord_times.values()) < 2:
        raise RuntimeError("tutorial must teach simultaneous input")
    print(f"validated {len(manifests)} songs and {sum(len(item['notes']) for item in manifests)} notes")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-dir", type=pathlib.Path, default=pathlib.Path("/private/tmp/jf-rhythm-wav"))
    parser.add_argument("--validate-only", action="store_true")
    parser.add_argument("--tutorial-only", action="store_true")
    args = parser.parse_args()
    if not FFMPEG.exists():
        raise SystemExit("ffmpeg is required at /opt/homebrew/bin/ffmpeg")
    if args.tutorial_only:
        build_tutorial()
    elif not args.validate_only:
        build_cc0(args.source_dir)
        build_tutorial()
    validate_catalog()


if __name__ == "__main__":
    main()
