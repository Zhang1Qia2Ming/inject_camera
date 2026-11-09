#pragma once

#include <algorithm>
#include <array>
#include <cstddef>
#include <limits>
#include <numeric>

struct SynchronizedLoadPlan {
    bool valid{false};
    std::size_t output_frames{0};
    std::array<std::size_t, 3> source_frames{};
    std::array<std::size_t, 3> load_bytes{};
};

inline SynchronizedLoadPlan synchronized_load_plan(
    const std::array<std::size_t, 3> &file_bytes,
    const std::array<unsigned, 3> &repeat_count,
    std::size_t frame_bytes,
    std::size_t memory_budget) {
    SynchronizedLoadPlan plan;
    if (frame_bytes == 0U)
        return plan;

    std::size_t output_quantum = 1U;
    for (const unsigned repeat : repeat_count) {
        if (repeat == 0U)
            return plan;
        const std::size_t divisor = std::gcd(output_quantum,
                                             static_cast<std::size_t>(repeat));
        const std::size_t factor =
            static_cast<std::size_t>(repeat) / divisor;
        if (output_quantum > std::numeric_limits<std::size_t>::max() / factor)
            return plan;
        output_quantum *= factor;
    }

    std::size_t bytes_per_quantum = 0U;
    std::size_t max_output_frames =
        std::numeric_limits<std::size_t>::max();
    for (std::size_t i = 0U; i < file_bytes.size(); ++i) {
        const std::size_t frames = file_bytes[i] / frame_bytes;
        const std::size_t repeat = repeat_count[i];
        if (frames == 0U ||
            frames > std::numeric_limits<std::size_t>::max() / repeat)
            return plan;
        max_output_frames =
            std::min(max_output_frames, frames * repeat);

        const std::size_t frames_per_quantum = output_quantum / repeat;
        if (frames_per_quantum >
            (std::numeric_limits<std::size_t>::max() - bytes_per_quantum) /
                frame_bytes)
            return plan;
        bytes_per_quantum += frames_per_quantum * frame_bytes;
    }

    if (bytes_per_quantum == 0U)
        return plan;
    const std::size_t cycles = std::min(max_output_frames / output_quantum,
                                        memory_budget / bytes_per_quantum);
    if (cycles == 0U)
        return plan;

    plan.output_frames = cycles * output_quantum;
    for (std::size_t i = 0U; i < file_bytes.size(); ++i) {
        plan.source_frames[i] = plan.output_frames / repeat_count[i];
        plan.load_bytes[i] = plan.source_frames[i] * frame_bytes;
    }
    plan.valid = true;
    return plan;
}
