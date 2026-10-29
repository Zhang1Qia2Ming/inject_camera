// Three independent RAW12 senders. One write() is one frame, so the
// FPGA sees a single tlast at the end of the 12,441,600 byte image.
// Stop a lane from stdin: "stop 0", "stop 1" or "stop 2".

#include <atomic>
#include <cstdint>
#include <cstring>
#include <fstream>
#include <iostream>
#include <string>
#include <thread>
#include <vector>

#include <cerrno>
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

std::size_t mem_available_bytes() {
    std::ifstream in("/proc/meminfo");
    std::string key;
    std::string unit;
    unsigned long long kb = 0;
    while (in >> key >> kb >> unit) {
        if (key == "MemAvailable:")
            return static_cast<std::size_t>(kb) * 1024ULL;
    }
    return 0;
}

std::size_t file_size(const std::string &path) {
    std::ifstream in(path, std::ios::binary);
    if (!in)
        return 0;
    in.seekg(0, std::ios::end);
    return static_cast<std::size_t>(in.tellg());
}

bool load_frames(const std::string &path, std::vector<char> &bytes,
                 std::size_t max_bytes) {
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
    std::size_t take = len;
    if (max_bytes < len)
        take = (max_bytes / kFrameBytes) * kFrameBytes;
    if (take == 0) {
        std::cerr << path << " no frame fits in the memory budget\n";
        return false;
    }
    in.seekg(0, std::ios::beg);
    bytes.resize(take);
    in.read(bytes.data(), static_cast<std::streamsize>(take));
    if (static_cast<std::size_t>(in.gcount()) != take)
        return false;
    std::cout << path << " loaded " << (take / kFrameBytes) << "/"
              << (len / kFrameBytes) << " frames\n"
              << std::flush;
    return true;
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
            std::cerr << "lane " << index << " write returned " << n
                      << " errno " << errno << " " << std::strerror(errno)
                      << "\n";
            break;
        }
        sent++;
        if ((sent % 30) == 0)
            std::cout << "lane " << index << " frames " << sent << "\n"
                      << std::flush;
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

    const char *lane_name[3] = {"TX1 front 30", "TX2 front 120", "TX4 rear 120"};
    std::size_t sizes[3];
    std::size_t total = 0;
    for (int i = 0; i < 3; i++) {
        sizes[i] = file_size(argv[i + 1]);
        if (sizes[i] == 0) {
            std::cerr << "cannot open " << argv[i + 1] << "\n";
            return 1;
        }
        total += sizes[i];
    }
    const std::size_t reserve = 6ULL << 30;
    const std::size_t avail = mem_available_bytes();
    const std::size_t budget = avail > reserve ? avail - reserve : avail / 2;
    std::size_t caps[3];
    if (total <= budget) {
        for (int i = 0; i < 3; i++)
            caps[i] = sizes[i];
    } else {
        std::cout << "raw files are " << total << " bytes, budget " << budget
                  << "; loading the same fraction of each lane\n"
                  << std::flush;
        for (int i = 0; i < 3; i++)
            caps[i] = static_cast<std::size_t>(
                (static_cast<unsigned __int128>(sizes[i]) * budget) / total);
    }

    std::vector<char> frames[3];
    for (int i = 0; i < 3; i++) {
        std::cout << "lane " << i << " " << lane_name[i] << "\n" << std::flush;
        if (!load_frames(argv[i + 1], frames[i], caps[i]))
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
