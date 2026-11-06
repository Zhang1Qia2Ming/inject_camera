#pragma once

#include <cstddef>
#include <stdexcept>

class FrameRepeater {
public:
    FrameRepeater(std::size_t frame_count, unsigned repeat_count)
        : frame_count_(frame_count), repeat_count_(repeat_count) {
        if (frame_count_ == 0)
            throw std::invalid_argument("frame_count must be at least 1");
        if (repeat_count_ == 0)
            throw std::invalid_argument("repeat_count must be at least 1");
    }

    std::size_t frame_index() const {
        return frame_index_;
    }

    std::size_t cursor_bytes(std::size_t frame_bytes) const {
        return frame_index_ * frame_bytes;
    }

    void advance() {
        repeat_index_++;
        if (repeat_index_ < repeat_count_)
            return;
        repeat_index_ = 0;
        frame_index_++;
        if (frame_index_ == frame_count_)
            frame_index_ = 0;
    }

private:
    const std::size_t frame_count_;
    const unsigned repeat_count_;
    std::size_t frame_index_{0};
    unsigned repeat_index_{0};
};
