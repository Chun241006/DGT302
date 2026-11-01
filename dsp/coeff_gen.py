import os
import numpy as np
import scipy.signal as signal
import matplotlib.pyplot as plt

# Tự động xác định đường dẫn tuyệt đối
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__))) if '__file__' in locals() else os.getcwd()
COEFF_DIR = os.path.join(BASE_DIR, 'dsp', 'coefficients')
PLOT_DIR = os.path.join(BASE_DIR, 'dsp', 'plots')

os.makedirs(COEFF_DIR, exist_ok=True)
os.makedirs(PLOT_DIR, exist_ok=True)

FS = 48000         # Sampling Rate: 48 kHz
NUM_TAPS = 31      # Odd Taps -> Linear Phase Type-1 (Group Delay D = 15 samples)

# Tần số cắt tối ưu giảm chồng lấn ở vùng 100 - 1000 Hz
BASS_CUTOFF = 200
MID_CUTOFFS = [250, 3800]
TREBLE_CUTOFF = 4000

def float_to_q115_hex(val):
    """Chuyển đổi float sang 16-bit Q1.15 Signed 2's Complement Hex."""
    qval = int(round(val * 32768))
    qval = max(min(qval, 32767), -32768)  # Saturation
    if qval < 0:
        qval = (1 << 16) + qval
    return f"{qval:04X}"

# 1. Thiết kế bộ lọc FIR Cửa sổ Hamming
h_bass = signal.firwin(NUM_TAPS, BASS_CUTOFF, fs=FS, pass_zero='lowpass')
h_mid = signal.firwin(NUM_TAPS, MID_CUTOFFS, fs=FS, pass_zero='bandpass')
h_treble = signal.firwin(NUM_TAPS, TREBLE_CUTOFF, fs=FS, pass_zero='highpass')

filters = {'bass': h_bass, 'mid': h_mid, 'treble': h_treble}

# 2. Xuất các file .mem vào dsp/coefficients/
for name, coeffs in filters.items():
    hex_lines = [float_to_q115_hex(c) for c in coeffs]
    path = os.path.join(COEFF_DIR, f'{name}_coeff.mem')
    with open(path, 'w') as f:
        f.write('\n'.join(hex_lines) + '\n')

# 3. Vẽ đồ thị Frequency Response và lưu vào dsp/plots/
for name, coeffs in filters.items():
    w, h = signal.freqz(coeffs, worN=1024, fs=FS)
    plt.figure(figsize=(7, 3.5))
    plt.plot(w, 20 * np.log10(np.abs(h) + 1e-12), 'b', linewidth=2)
    plt.title(f'{name.capitalize()} Filter Response (FIR {NUM_TAPS} Taps)')
    plt.xlabel('Frequency (Hz)')
    plt.ylabel('Magnitude (dB)')
    plt.grid(True)
    plt.ylim([-60, 5])
    plt.tight_layout()
    plt.savefig(os.path.join(PLOT_DIR, f'{name}_response.png'), dpi=300)
    plt.close()

print(f"[+] Đã tạo các file hệ số tại: {COEFF_DIR}")
print(f"[+] Đã tạo các đồ thị đáp ứng tần số tại: {PLOT_DIR}")