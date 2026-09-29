## 0.2.2

- Reassemble CAN responses across BLE notifications, including fragmented headers and terminators.
- Handle multiple frames per notification and ignore adapter acknowledgements, other nodes, and malformed frames.
- Bound incomplete-frame buffering and add regression tests for CAN framing and SDO transfers.

## 0.0.1

Initial release.

## 0.1.0

Added CAN Protocol.
