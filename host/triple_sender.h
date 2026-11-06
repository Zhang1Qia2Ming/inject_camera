#pragma once

#include "frame_buffer.h"
#include "frame_pacer.h"
#include "frame_repeater.h"
#include "xdma_h2c.h"

#include <atomic>
#include <cstdint>
#include <cstring>
#include <fstream>
#include <iostream>
#include <string>
#include <thread>
#include <vector>

namespace triple_sender {

inline std::atomic<bool> run_lane[3]{{true}, {true}, {true}};

inline std::size_t mem_available_bytes() {
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

inline void send_lane(int index,
                      std::vector<char> frames,
                      unsigned repeat_count,
                      const FrameFormat &format) {
    const int fd = open_h2c_channel(index);
    if (fd < 0) {
        run_lane[index] = false;
        return;
    }

    FramePacer pacer;
    FrameRepeater repeater(frames.size() / format.frame_bytes, repeat_count);
    std::uint64_t sent = 0;
    while (run_lane[index]) {
        const char *frame =
            frames.data() + repeater.cursor_bytes(format.frame_bytes);
        if (!write_full_frame(fd, frame, format.frame_bytes)) {
            std::cerr << "lane " << index
                      << " incomplete frame write; stopping to preserve TLAST"
                      << " errno " << errno << " " << std::strerror(errno)
                      << "\n";
            break;
        }
        ++sent;
        if ((sent % 30) == 0)
            std::cout << "lane " << index << " frames " << sent << "\n"
                      << std::flush;
        repeater.advance();
        pacer.wait_next();
    }

    close(fd);
    run_lane[index] = false;
    std::cout << "lane " << index << " stopped after " << sent << " frames\n";
}

inline int run(int argc, char **argv, const FrameFormat &format) {
    if (argc != 4) {
        std::cerr << "usage: " << argv[0]
                  << " tx1." << format.name
                  << " tx2." << format.name
                  << " tx4." << format.name << "\n"
                  << "stdin: stop 0 | stop 1 | stop 2 | quit\n";
        return 1;
    }

    const char *lane_name[3] = {
        "TX1 front far 30deg", "TX2 front wide 120deg",
        "TX4 rear 120deg"};
    const unsigned source_fps[3] = {10, 30, 10};
    const unsigned repeat_count[3] = {3, 1, 3};

    std::size_t sizes[3];
    std::size_t total = 0;
    for (int i = 0; i < 3; ++i) {
        sizes[i] = frame_file_size(argv[i + 1]);
        if (sizes[i] == 0) {
            std::cerr << "cannot open " << argv[i + 1] << "\n";
            return 1;
        }
        total += sizes[i];
        run_lane[i] = true;
    }

    const std::size_t reserve = 6ULL << 30;
    const std::size_t available = mem_available_bytes();
    const std::size_t budget =
        available > reserve ? available - reserve : available / 2;
    std::size_t caps[3];
    if (total <= budget) {
        for (int i = 0; i < 3; ++i)
            caps[i] = sizes[i];
    } else {
        std::cout << "frame files are " << total << " bytes, budget "
                  << budget << "; loading the same fraction of each lane\n";
        for (int i = 0; i < 3; ++i) {
            caps[i] = static_cast<std::size_t>(
                (static_cast<unsigned __int128>(sizes[i]) * budget) / total);
        }
    }

    std::vector<char> frames[3];
    for (int i = 0; i < 3; ++i) {
        std::cout << "lane " << i << " " << lane_name[i] << ": "
                  << format.name << " source " << source_fps[i]
                  << " Hz -> output 30 Hz, repeat " << repeat_count[i]
                  << "x\n";
        if (!load_frame_file(argv[i + 1], format, caps[i], frames[i]))
            return 1;
        std::cout << argv[i + 1] << " loaded "
                  << (frames[i].size() / format.frame_bytes) << "/"
                  << (sizes[i] / format.frame_bytes) << " frames\n";
    }

    std::thread lanes[3];
    for (int i = 0; i < 3; ++i) {
        lanes[i] = std::thread(
            send_lane, i, std::move(frames[i]), repeat_count[i],
            std::cref(format));
    }

    std::string line;
    while (std::getline(std::cin, line)) {
        if (line == "quit") {
            for (auto &running : run_lane)
                running = false;
            break;
        }
        if (line.rfind("stop ", 0) == 0 && line.size() == 6 &&
            line[5] >= '0' && line[5] <= '2') {
            run_lane[line[5] - '0'] = false;
        }
    }
    for (auto &lane : lanes)
        lane.join();
    return 0;
}

}  // namespace triple_sender
