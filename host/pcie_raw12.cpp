// Three independent RAW12 senders. One write() is one frame, so the
// FPGA sees a single tlast at the end of the 12,441,600 byte image.
// Stop a lane from stdin: "stop 0", "stop 1" or "stop 2".

#include <atomic>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <string>
#include <thread>
#include <vector>

#include <fcntl.h>
#include <unistd.h>

namespace {

constexpr std::size_t kFrameBytes = 12441600;

std::atomic<bool> g_run[3]{{true}, {true}, {true}};

int open_h2c(int index) {
    const std::string path = "/dev/xdma0_h2c_" + std::to_string(index);
    const int fd = open(path.c_str(), O_WRONLY);
    if (fd < 0)
        std::perror(path.c_str());
    return fd;
}

bool load_frames(const std::string &path, std::vector<char> &bytes) {
    std::ifstream in(path, std::ios::binary);
    if (!in) {
        std::cerr << "cannot open " << path << "\n";
        return false;
    }
    in.seekg(0, std::ios::end);
    const auto len = static_cast<std::size_t>(in.tellg());
    if (len == 0 || (len % kFrameBytes) != 0) {
        std::cerr << path << " size " << len
                  << " is not a multiple of " << kFrameBytes << "\n";
        return false;
    }
    in.seekg(0, std::ios::beg);
    bytes.resize(len);
    in.read(bytes.data(), static_cast<std::streamsize>(len));
    return static_cast<std::size_t>(in.gcount()) == len;
}

void send_lane(int index, std::vector<char> frames) {
    const int fd = open_h2c(index);
    if (fd < 0) {
        g_run[index] = false;
        return;
    }
    std::uint64_t sent = 0;
    std::size_t cursor = 0;
    while (g_run[index]) {
        const ssize_t n = write(fd, frames.data() + cursor, kFrameBytes);
        if (n != static_cast<ssize_t>(kFrameBytes)) {
            std::cerr << "lane " << index << " write returned " << n << "\n";
            break;
        }
        sent++;
        if ((sent % 30) == 0)
            std::cout << "lane " << index << " frames " << sent << "\n";
        cursor += kFrameBytes;
        if (cursor >= frames.size())
            cursor = 0;
    }
    close(fd);
    g_run[index] = false;
    std::cout << "lane " << index << " stopped after " << sent << " frames\n";
}

}  // namespace

int main(int argc, char **argv) {
    if (argc != 4) {
        std::cerr << "usage: pcie_raw12 tx1.raw tx2.raw tx4.raw\n"
                  << "stdin: stop 0 | stop 1 | stop 2 | quit\n";
        return 1;
    }

    std::vector<char> frames[3];
    for (int i = 0; i < 3; i++) {
        if (!load_frames(argv[i + 1], frames[i]))
            return 1;
    }

    std::thread lanes[3];
    for (int i = 0; i < 3; i++)
        lanes[i] = std::thread(send_lane, i, std::move(frames[i]));

    std::string line;
    while (std::getline(std::cin, line)) {
        if (line == "quit") {
            for (int i = 0; i < 3; i++)
                g_run[i] = false;
            break;
        }
        if (line.rfind("stop ", 0) == 0 && line.size() == 6 &&
            line[5] >= '0' && line[5] <= '2') {
            g_run[line[5] - '0'] = false;
        }
    }

    for (int i = 0; i < 3; i++)
        lanes[i].join();
    return 0;
}
