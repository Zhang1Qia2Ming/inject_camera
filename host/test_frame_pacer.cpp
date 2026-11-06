#include "frame_pacer.h"

#include <cassert>
#include <chrono>

int main() {
    using Clock = std::chrono::steady_clock;
    using namespace std::chrono_literals;

    const Clock::time_point start{};

    assert(next_frame_deadline(start, start + 1ms) ==
           start + kFramePeriod);

    assert(next_frame_deadline(start, start + 50ms) ==
           start + 50ms + kFramePeriod);

    assert(next_frame_deadline(start + kFramePeriod,
                               start + kFramePeriod + 1ms) ==
           start + 2 * kFramePeriod);
    return 0;
}
