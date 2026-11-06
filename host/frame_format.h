#pragma once

#include <cstddef>
#include <cstdint>

struct FrameFormat {
    const char *name;
    std::uint32_t width;
    std::uint32_t height;
    std::size_t line_bytes;
    std::size_t frame_bytes;
    std::uint32_t line_beats;
};

inline const FrameFormat &raw12_bggr_3840x2160() {
    static constexpr FrameFormat format{
        "raw12_bggr", 3840, 2160, 5760, 12441600, 360};
    return format;
}

inline const FrameFormat &uyvy422_3840x2160() {
    static constexpr FrameFormat format{
        "uyvy422", 3840, 2160, 7680, 16588800, 480};
    return format;
}
