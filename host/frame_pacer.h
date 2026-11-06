#pragma once

#include <chrono>
#include <thread>

inline constexpr std::chrono::nanoseconds kFramePeriod{33333333};

inline std::chrono::steady_clock::time_point next_frame_deadline(
    std::chrono::steady_clock::time_point previous,
    std::chrono::steady_clock::time_point now) {
    const auto scheduled = previous + kFramePeriod;
    return scheduled < now ? now + kFramePeriod : scheduled;
}

class FramePacer {
public:
    FramePacer() : deadline_(std::chrono::steady_clock::now()) {}

    void wait_next() {
        deadline_ = next_frame_deadline(
            deadline_, std::chrono::steady_clock::now());
        std::this_thread::sleep_until(deadline_);
    }

private:
    std::chrono::steady_clock::time_point deadline_;
};
