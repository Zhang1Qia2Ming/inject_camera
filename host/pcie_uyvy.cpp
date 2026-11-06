#include "frame_format.h"
#include "triple_sender.h"

int main(int argc, char **argv) {
    return triple_sender::run(argc, argv, uyvy422_3840x2160());
}
