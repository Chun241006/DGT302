import os

# Tự động xác định đường dẫn thư mục data/
CURRENT_DIR = os.getcwd()
DATA_DIR = os.path.join(CURRENT_DIR, 'data')

input_path = os.path.join(DATA_DIR, 'input_samples.mem')
output_path = os.path.join(DATA_DIR, 'expected_output.mem')
vectors_path = os.path.join(DATA_DIR, 'vectors.txt')

if not os.path.exists(input_path) or not os.path.exists(output_path):
    print("[-] Thiếu file input_samples.mem hoặc expected_output.mem! Hãy chạy test_data.py và golden_model.py trước.")
else:
    with open(input_path, 'r') as f_in, open(output_path, 'r') as f_out:
        inputs = [line.strip() for line in f_in if line.strip()]
        outputs = [line.strip() for line in f_out if line.strip()]

    # Ghép 2 cột: Cột 1 là INPUT_HEX, Cột 2 là EXPECTED_HEX
    with open(vectors_path, 'w') as f_vec:
        for inp, outp in zip(inputs, outputs):
            f_vec.write(f"{inp} {outp}\n")

    print(f"[+] Đã phối hợp tạo thành công file Testbench Vector tại: {vectors_path}")