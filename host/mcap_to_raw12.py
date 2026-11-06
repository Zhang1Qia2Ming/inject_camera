#!/usr/bin/env python3
"""Compatibility entry point for RAW12 MCAP conversion."""

import sys

from mcap_convert import main
from mcap_formats import pack_bayer_bggr

__all__ = ["pack_bayer_bggr"]


if __name__ == "__main__":
    sys.exit(main(default_format="raw12"))
