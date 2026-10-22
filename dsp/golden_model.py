import os

# Tự động tìm thư mục làm việc
CURRENT_DIR = os.getcwd()
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

def hex_to_signed16(hex_str):
    val = int(hex_str, 16)
    return val - 65536 if val & 0x8000 else val

def signed_to_hex16(val):
    # Saturation (Xén biên 16-bit signed: [-32768, 32767])
    val = max(min(val, 32767), -32768)
    if val < 0:
        val = (1 << 16) + val
    return f"{val:04X}"

def find_file(filename):
    """Tìm file linh hoạt ở mọi vị trí thư mục khả thi"""
    possible_paths = [
        os.path.join(CURRENT_DIR, filename),
        os.path.join(SCRIPT_DIR, filename),
        os.path.join(CURRENT_DIR, 'dsp', filename),
        os.path.join(SCRIPT_DIR, '..', filename),
        os.path.join(CURRENT_DIR, '..', filename)
    ]
    for p in possible_paths:
        if os.path.exists(p):
            return p
    raise FileNotFoundError(
        f"Không tìm thấy file '{filename}'.\n"
        f"Hãy kiểm tra lại xem file đã được tạo ra trong thư mục 'coefficients/' hay 'dsp/coefficients/' chưa!"
    )

def load_coeffs(coeff_filename):
    abs_path = find_file(os.path.join('coefficients', coeff_filename))
    with open(abs_path, 'r') as f:
        return [hex_to_signed16(line.strip()) for line in f if line.strip()]

def saturate16(val):
    """Mô phỏng module saturation.v trong RTL"""
    return max(min(val, 32767), -32768)

def run_golden_model(input_rel_path, output_rel_path, g_b=1.0, g_m=1.0, g_t=1.0):
    # 1. Đọc hệ số Q1.15
    hb = load_coeffs('bass_coeff.mem')
    hm = load_coeffs('mid_coeff.mem')
    ht = load_coeffs('treble_coeff.mem')

    # 2. Quy đổi Gain sang Q8.8 Integer (16'sd256 = Unity 1.0)
    gb_int = int(round(g_b * 256))
    gm_int = int(round(g_m * 256))
    gt_int = int(round(g_t * 256))

    # 3. Đọc dữ liệu mẫu đầu vào
    input_abs_path = find_file(input_rel_path)
    with open(input_abs_path, 'r') as f:
        x_samples = [hex_to_signed16(line.strip()) for line in f if line.strip()]

    num_taps = len(hb)
    shift_reg = [0] * num_taps
    output_hex = []

    # 4. TÍNH TOÁN TỪNG SAMPLE (BIT-EXACT VỚI VERILOG RTL)
    for x in x_samples:
        # Cập nhật thanh ghi dịch delay_line
        shift_reg = [x] + shift_reg[:-1]

        # BƯỚC 1: FIR FILTER (Accumulate in 37-bit, shift right 15, saturate 16-bit)
        acc_b = sum(shift_reg[i] * hb[i] for i in range(num_taps))
        acc_m = sum(shift_reg[i] * hm[i] for i in range(num_taps))
        acc_t = sum(shift_reg[i] * ht[i] for i in range(num_taps))

        yb = saturate16(acc_b >> 15)
        ym = saturate16(acc_m >> 15)
        yt = saturate16(acc_t >> 15)

        # BƯỚC 2: GAIN CONTROL (Q8.8, multiply -> shift right 8 -> saturate 16-bit)
        yb_g = saturate16((yb * gb_int) >> 8)
        ym_g = saturate16((ym * gm_int) >> 8)
        yt_g = saturate16((yt * gt_int) >> 8)

        # BƯỚC 3: MIXER & FINAL SATURATION (Sum in 18-bit signed -> saturate 16-bit)
        mixed_18bit = yb_g + ym_g + yt_g
        final_out = saturate16(mixed_18bit)

        output_hex.append(signed_to_hex16(final_out))

    # Xuất file kết quả
    output_abs_path = os.path.join(CURRENT_DIR, output_rel_path)
    os.makedirs(os.path.dirname(output_abs_path), exist_ok=True)

    with open(output_abs_path, 'w') as f:
        f.write('\n'.join(output_hex) + '\n')

    print(f"[+] Đã chạy Golden Model thành công và xuất file: {output_abs_path}")

if __name__ == "__main__":
    # Mặc định chạy Gain = 1.0 (Q8.8 = 256)
    run_golden_model('data/input_samples.mem', 'data/expected_output.mem', g_b=1.0, g_m=1.0, g_t=1.0)