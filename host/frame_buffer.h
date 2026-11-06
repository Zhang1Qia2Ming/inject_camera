#pragma once

#include "frame_format.h"

#include <fstream>
#include <iostream>
#include <string>
#include <vector>

inline std::size_t frame_file_size(const std::string &path) {
    std::ifstream in(path, std::ios::binary | std::ios::ate);
    if (!in)
        return 0;
    return static_cast<std::size_t>(in.tellg());
}

inline bool load_frame_file(const std::string &path,
                            const FrameFormat &format,
                            std::size_t max_bytes,
                            std::vector<char> &bytes) {
    bytes.clear();
    std::ifstream in(path, std::ios::binary | std::ios::ate);
    if (!in) {
        std::cerr << "cannot open " << path << "\n";
        return false;
    }

    const std::size_t length = static_cast<std::size_t>(in.tellg());
    if (length == 0 || (length % format.frame_bytes) != 0) {
        std::cerr << path << " size " << length << " is not a multiple of "
                  << format.frame_bytes << " for " << format.name << "\n";
        return false;
    }

    const std::size_t take =
        (length <= max_bytes)
            ? length
            : (max_bytes / format.frame_bytes) * format.frame_bytes;
    if (take == 0) {
        std::cerr << path << " no frame fits in the memory budget\n";
        return false;
    }

    bytes.resize(take);
    in.seekg(0, std::ios::beg);
    in.read(bytes.data(), static_cast<std::streamsize>(take));
    if (static_cast<std::size_t>(in.gcount()) != take) {
        bytes.clear();
        return false;
    }
    return true;
}
