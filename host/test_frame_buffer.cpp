#include "frame_buffer.h"

#include <cassert>
#include <cstdio>
#include <fstream>
#include <vector>

namespace {

void write_bytes(const char *path, std::size_t count) {
    std::ofstream out(path, std::ios::binary);
    std::vector<char> bytes(count, static_cast<char>(0x5a));
    out.write(bytes.data(), static_cast<std::streamsize>(bytes.size()));
}

}  // namespace

int main() {
    const FrameFormat tiny{"tiny", 4, 2, 8, 16, 1};
    std::vector<char> frames;

    const char *valid = "/tmp/test_frame_buffer_valid.bin";
    write_bytes(valid, 48);
    assert(load_frame_file(valid, tiny, 40, frames));
    assert(frames.size() == 32);

    const char *invalid = "/tmp/test_frame_buffer_invalid.bin";
    write_bytes(invalid, 17);
    assert(!load_frame_file(invalid, tiny, 64, frames));

    assert(!load_frame_file(valid, tiny, 15, frames));
    assert(!load_frame_file("/tmp/does_not_exist_frame.bin", tiny, 64, frames));

    std::remove(valid);
    std::remove(invalid);
    return 0;
}
