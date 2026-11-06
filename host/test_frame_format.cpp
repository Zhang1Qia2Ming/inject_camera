#include "frame_format.h"

#include <cassert>

int main() {
    const FrameFormat &raw12 = raw12_bggr_3840x2160();
    assert(raw12.width == 3840);
    assert(raw12.height == 2160);
    assert(raw12.line_bytes == 5760);
    assert(raw12.frame_bytes == 12441600);
    assert(raw12.line_beats == 360);

    const FrameFormat &uyvy = uyvy422_3840x2160();
    assert(uyvy.width == 3840);
    assert(uyvy.height == 2160);
    assert(uyvy.line_bytes == 7680);
    assert(uyvy.frame_bytes == 16588800);
    assert(uyvy.line_beats == 480);
    return 0;
}
