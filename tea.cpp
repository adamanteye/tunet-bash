#include <array>
#include <cstring>
#include <fstream>
#include <iostream>
#include <memory>
#include <sstream>
#include <vector>

class AuthTea {
  public:
    std::array<uint32_t, 4> k;

    explicit AuthTea(const uint8_t* key, size_t key_len) {
        size_t len = std::min(key_len, static_cast<size_t>(16));
        std::array<uint8_t, 16> full_key = {0};
        std::memcpy(full_key.data(), key, len);
        for (int i = 0; i < 4; ++i) {
            k[i] = read_u32(full_key.data() + i * 4, full_key.size() - i * 4);
        }
    }

    static void to_u32_with_len(const uint8_t* a, size_t a_len,
                                std::unique_ptr<uint8_t[]>& out,
                                size_t& out_len) {
        size_t n = (a_len + 3) / 4;
        out_len = (n + 1) * 4;
        out = std::make_unique<uint8_t[]>(out_len);
        std::memset(out.get(), 0, out_len);
        std::memcpy(out.get(), a, a_len);
        out[out_len - 4] = static_cast<uint8_t>(a_len & 0xFF);
        out[out_len - 3] = static_cast<uint8_t>((a_len >> 8) & 0xFF);
        out[out_len - 2] = static_cast<uint8_t>((a_len >> 16) & 0xFF);
        out[out_len - 1] = static_cast<uint8_t>((a_len >> 24) & 0xFF);
    }

    static uint32_t read_u32(const uint8_t* slice, size_t length) {
        uint8_t buffer[4] = {0};
        size_t copy_len = std::min(static_cast<size_t>(4), length);
        std::memcpy(buffer, slice, copy_len);
        return static_cast<uint32_t>(buffer[0]) |
               (static_cast<uint32_t>(buffer[1]) << 8) |
               (static_cast<uint32_t>(buffer[2]) << 16) |
               (static_cast<uint32_t>(buffer[3]) << 24);
    }

    static void write_u32(uint8_t* slice, uint32_t value) {
        slice[0] = static_cast<uint8_t>(value & 0xFF);
        slice[1] = static_cast<uint8_t>((value >> 8) & 0xFF);
        slice[2] = static_cast<uint8_t>((value >> 16) & 0xFF);
        slice[3] = static_cast<uint8_t>((value >> 24) & 0xFF);
    }

    void encode(const uint8_t* data, size_t data_len,
                std::unique_ptr<uint8_t[]>& out, size_t& out_len) const {
        std::unique_ptr<uint8_t[]> v;
        size_t v_len;
        to_u32_with_len(data, data_len, v, v_len);
        size_t n = v_len / 4 - 1;
        uint32_t d = 0;
        uint32_t z = read_u32(v.get() + n * 4, v_len - n * 4);
        uint32_t q = 6 + 52 / (n + 1);
        for (uint32_t i = 0; i < q; ++i) {
            d += 0x9E3779B9;
            uint32_t e = (d >> 2) & 3;
            for (size_t p = 0; p <= n; ++p) {
                uint32_t y = read_u32(v.get() + ((p + 1) % (n + 1)) * 4,
                                      v_len - ((p + 1) % (n + 1)) * 4);
                uint32_t m = (z >> 5) ^ (y << 2);
                m += ((y >> 3) ^ (z << 4) ^ (d ^ y));
                m += k[(p & 3) ^ e] ^ z;
                m += read_u32(v.get() + p * 4, v_len - ((p + 1) % (n + 1)) * 4);
                write_u32(v.get() + p * 4, m);
                z = m;
            }
        }
        out = std::move(v);
        out_len = v_len;
    }
};

bool read_file_content(const std::string& filename, std::string& content) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Error: Unable to open file " << filename << std::endl;
        return false;
    }
    std::ostringstream oss;
    oss << file.rdbuf();
    content = oss.str();
    return true;
}

int main(int argc, char* argv[]) {
    if (argc < 3) {
        std::cerr << "Usage: " << argv[0] << " <key> <data_file>" << std::endl;
        return 1;
    }

    const std::string key_str = argv[1];
    const std::string data_file = argv[2];

    std::vector<uint8_t> key(key_str.begin(), key_str.end());

    std::string data_str;
    if (!read_file_content(data_file, data_str)) {
        return 1;
    }

    std::vector<uint8_t> data(data_str.begin(), data_str.end());

    AuthTea authtea(key.data(), key.size());
    std::unique_ptr<uint8_t[]> encoded_data;
    size_t encoded_data_len;
    authtea.encode(data.data(), data.size(), encoded_data, encoded_data_len);
    for (size_t i = 0; i < encoded_data_len; ++i) {
        std::cout << std::hex << static_cast<int>(encoded_data[i]);
    }
    std::cout << std::endl;
    std::ofstream output_file("encoded_output.bin", std::ios::binary);
    if (!output_file.is_open()) {
        std::cerr << "Error: Unable to open output file for writing."
                  << std::endl;
        return 1;
    }
    output_file.write(reinterpret_cast<char*>(encoded_data.get()),
                      encoded_data_len);
    output_file.close();
    return 0;
}
