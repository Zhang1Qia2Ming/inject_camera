#!/usr/bin/env python3
"""Compatibility entry point for packed UYVY422 MCAP conversion."""

import sys

from mcap_convert import main


if __name__ == "__main__":
    sys.exit(main(default_format="uyvy422"))
