## 0.2.4

- Add awaitable, idempotent BleIo.dispose to cancel notifications before BLE disconnect.
- Reject I/O after disposal and release response listeners after failed calls.

## 0.2.3

- Ignore mismatched object addresses and response types during normal SDO upload/download initiation, continuing to wait within the existing timeout.
- Preserve matching aborts, segmented transfers, and block-download frame handling.
- Add regression coverage for stale responses, coalesced/fragmented notifications, and block-download sequence bytes.

## 0.2.2

- Reassemble CAN responses across BLE notifications, including fragmented headers and terminators.
- Handle multiple frames per notification and ignore adapter acknowledgements, other nodes, and malformed frames.
- Bound incomplete-frame buffering and add regression tests for CAN framing and SDO transfers.

## 0.0.1

Initial release.

## 0.1.0

Added CAN Protocol.
