#include "synchronized_load_plan.h"

#include <array>
#include <cassert>
#include <cstddef>

int main() {
    constexpr std::size_t frame_bytes = 3840ULL * 2160ULL * 2ULL;
    const std::array<std::size_t, 3> file_bytes = {
        398ULL * frame_bytes,
        1198ULL * frame_bytes,
        400ULL * frame_bytes,
    };
    const std::array<unsigned, 3> repeats = {3U, 1U, 3U};

    const auto constrained =
        synchronized_load_plan(file_bytes, repeats, frame_bytes, 17530748928ULL);
    assert(constrained.valid);
    assert(constrained.output_frames == 633U);
    assert((constrained.source_frames ==
            std::array<std::size_t, 3>{211U, 633U, 211U}));

    const auto complete =
        synchronized_load_plan(file_bytes, repeats, frame_bytes, 1ULL << 40);
    assert(complete.valid);
    assert(complete.output_frames == 1194U);
    assert((complete.source_frames ==
            std::array<std::size_t, 3>{398U, 1194U, 398U}));

    const auto too_small = synchronized_load_plan(
        file_bytes, repeats, frame_bytes, 5ULL * frame_bytes - 1ULL);
    assert(!too_small.valid);
    return 0;
}
