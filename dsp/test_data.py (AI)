import os
import numpy as np

# Tự động tạo thư mục data nếu chưa có
os.makedirs('data', exist_ok=True)

FS = 48000
DURATION = 0.005  # 5ms
t = np.arange(int(FS * DURATION)) / FS

# Tạo tín hiệu thử nghiệm các dải
s_zero = np.zeros(50)
s_100hz = 0.6 * np.sin(2 * np.pi * 100 * t)   # Test Bass
s_1khz = 0.6 * np.sin(2 * np.pi * 1000 * t)   # Test Mid
s_8khz = 0.6 * np.sin(2 * np.pi * 8000 * t)   # Test Treble
s_multi = (s_100hz + s_1khz + s_8khz) / 3.0    # Multitone

# Ghép nối các chuỗi dữ liệu
full_signal = np.concatenate([s_zero, s_100hz, s_1khz, s_8khz, s_multi])

# Ép kiểu Q1.15 Integer
q_signal = np.clip(np.round(full_signal * 32767), -32768, 32767).astype(int)

def to_hex16(val):
    if val < 0:
        val = (1 << 16) + val
    return f"{val:04X}"

hex_lines = [to_hex16(v) for v in q_signal]

with open('data/input_samples.mem', 'w') as f:
    f.write('\n'.join(hex_lines) + '\n')

print(f"[+] Đã tạo thành công data/input_samples.mem ({len(hex_lines)} samples)")
