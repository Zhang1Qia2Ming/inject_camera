#include "frame_repeater.h"

#include <cassert>
#include <cstddef>
#include <stdexcept>

int main() {
    FrameRepeater repeated(3, 3);
    const std::size_t expected_repeated[] = {0, 0, 0, 1, 1, 1, 2};
    for (const auto expected : expected_repeated) {
        assert(repeated.frame_index() == expected);
        repeated.advance();
    }

    FrameRepeater direct(3, 1);
    const std::size_t expected_direct[] = {0, 1, 2, 0};
    for (const auto expected : expected_direct) {
        assert(direct.frame_index() == expected);
        direct.advance();
    }

    FrameRepeater wraps(2, 3);
    for (int i = 0; i < 6; ++i)
        wraps.advance();
    assert(wraps.frame_index() == 0);

    bool rejected_zero_frames = false;
    try {
        FrameRepeater invalid(0, 1);
    } catch (const std::invalid_argument &) {
        rejected_zero_frames = true;
    }
    assert(rejected_zero_frames);

    bool rejected_zero_repeat = false;
    try {
        FrameRepeater invalid(1, 0);
    } catch (const std::invalid_argument &) {
        rejected_zero_repeat = true;
    }
    assert(rejected_zero_repeat);
    return 0;
}
