# 997 Sensor8 EBD reference

`997_sensor8_ebd_u16.mem` comes from the buffers passed to
`DevBlkCDIParseTopEmbDataInfo` and `DevBlkCDIParseBotEmbDataInfo` by the
successfully running Sensor8 thread (`SIPL_VI_ISP_8`) on the 997 HIL bench.
It is the receive-side NvSIPL reference, not the injection server input.

- Top: 15360 bytes, SHA256
  `6412b91e591c3073c87026f1e81f6a52def47212c58912da4684868e80855ac3`
- Bottom: 30720 bytes, SHA256
  `c4c557edbd1f42179e992bc62cbf58d743736b54efce5d6bb3a199428e29eb90`
- Combined uint16 fixture: 23040 slots, SHA256
  `dc71295b9bbebde4f1f0d7e6ee49b28d9860ed90e8de51a7480b49b82fdb8c10`

The 997 RTCPU trace proves that VI receives one `3840x2166` frame in
`VI_PIXFMT_FORMAT_T_U8_Y8__V8_Y8` format. Consequently, all 46080 captured
bytes are valid UYVY data: two top lines and four bottom lines, each with
7680 bytes. They must not be decoded as RAW12.

`gen_997_rx_ebd_mem.py` preserves all captured bytes. Only byte offsets 151
and 159, the values for OX08D registers `0x462C` and `0x462D`, are changed
at runtime to carry the current FPGA frame number.
