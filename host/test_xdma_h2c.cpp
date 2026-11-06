#include "xdma_h2c.h"

#include <cassert>
#include <cerrno>
#include <cstddef>
#include <vector>

namespace {

std::vector<ssize_t> g_results;
std::size_t g_call = 0;

ssize_t scripted_write(int, const void *, std::size_t count) {
    const ssize_t result = g_results.at(g_call++);
    if (result == -2) {
        errno = EINTR;
        return -1;
    }
    if (result < 0) {
        errno = EIO;
        return -1;
    }
    return result > static_cast<ssize_t>(count)
               ? static_cast<ssize_t>(count)
               : result;
}

bool run(const std::vector<ssize_t> &results) {
    char frame[16]{};
    g_results = results;
    g_call = 0;
    return write_full_frame_with(7, frame, sizeof(frame), scripted_write);
}

}  // namespace

int main() {
    assert(run({16}));
    assert(run({-2, 16}));
    assert(!run({4}));
    assert(!run({0}));
    assert(!run({-1}));
    return 0;
}
