# Pipelined Ethernet / IPv4/IPv6 / TCP/UDP Parser (VHDL)
## Overview
This project implements a fully pipelined, streaming Ethernet packet parser in VHDL.
It extracts L2/L3/L4 metadata from incoming frames using a multi-stage architecture designed for deterministic, high-throughput operation.

The design supports:
- Ethernet II frames
- Optional VLAN tagging (single and stacked)
- IPv4 and IPv6 detection
- TCP and UDP header parsing
- Payload offset computation
- Streaming metadata output

The architecture is parameterized and simulation-verified using a self-checking testbench.

## Architecture 
The parser is built as a 7-stage streaming pipeline using AXI-style ```valid/ready``` handshake propagation.
<img width="593" height="679" alt="image" src="https://github.com/user-attachments/assets/8c67ccb0-7cd3-4858-a0bd-88087296c6f3" />

Each stage
- Accepts streaming input
- Registers outputs
- Propagates backpressure via ```ready```
- Maintains single-cycle latency

## Streaming Interface
Parser uses a simplified AXI-style interface:

**Inputs**
- ```in_data```
- ```in_keep```
- ```in_valid```
- ```in_ready```
- ```in_sof```
- ```in_eof```

**Outputs**
- Destination MAC
- Source MAC
- VLAN count
- Ethertype
- IP version
- IP protocol
- IPv4 source/destination
- TCP/UDP source/destination ports
- Payload offset
- Flags

## Sliding Window Strategy
Stage 1 implements a fixed-offset 96-byte capture window:
- Byte 0 = first byte of Ethernet frame
- Byte 12–13 = Ethertype
- Byte 14 = IPv4 header (if applicable)
This allows deterministic random-access header parsing in later stages without dynamic shifting.

## Protocol Support
**Ethernet II**
- MAC extraction (dst/src)
- Ethertype detection

**VLAN**
- 802.1Q (0x8100)
- 802.1ad (0x88A8)
- 0x9100
- Supports stacked VLAN

**IPv4**
- Version detection
- Header length parsing
- Fragment detection
- L4 offset calculation

**IPv6**
- Version detection
- Fixed 40-byte header handling

**TCP**
- Data offset parsing
- Payload offset computation

**UDP**
- Fixed 8-byte header handling

## Parameterization
**Key generics**
```
generic (
  BPC          : positive := 1;   -- Bytes per cycle
  WINDOW_BYTES : positive := 96   -- Header capture window
);
```
This allows simulation scaling toward wider datapaths (e.g., 64-bit, 10G-style interfaces).

## Simulation
The project is verified using Vivado Behavioral Simulation. 

**The testbench injects a known packet**
- Ethernet II
- IPv4
- UDP
- Known MAC/IP/port values

**Waveform valiation confirms**
- Correct MAC extraction
- Correct Ethertype detection
- Proper L3/L4 offsets
- Correct TCP/UDP ports
- Proper metadata emission on EOF


## Future Improvements
- CRC32 verification stage
- 5-tuple hash generation
- Flow classification table
- 64-bit (8B/cycle) datapath validation
- Throughput and latency benchmarking
- Hardware demo on Artix-7
