#pragma once

#include <cerrno>
#include <cstddef>
#include <cstdio>
#include <string>

#include <fcntl.h>
#include <unistd.h>

using WriteOperation = ssize_t (*)(int, const void *, std::size_t);

inline int open_h2c_channel(int index) {
    const std::string path = "/dev/xdma0_h2c_" + std::to_string(index);
    const int fd = open(path.c_str(), O_WRONLY);
    if (fd < 0)
        std::perror(path.c_str());
    return fd;
}

inline bool write_full_frame_with(int fd,
                                  const void *data,
                                  std::size_t frame_bytes,
                                  WriteOperation write_operation) {
    ssize_t written;
    do {
        written = write_operation(fd, data, frame_bytes);
    } while (written < 0 && errno == EINTR);
    return written == static_cast<ssize_t>(frame_bytes);
}

inline bool write_full_frame(int fd,
                             const void *data,
                             std::size_t frame_bytes) {
    return write_full_frame_with(fd, data, frame_bytes, ::write);
}
