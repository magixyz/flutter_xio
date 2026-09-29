import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_xio/flutter_xio.dart';

class _BleIo extends Fake implements BleIo {
  final replies = <List<List<int>?>>[];
  final requests = <List<int>>[];
  int maxBuffered = 0;

  @override
  Future<List<int>?> call(
    List<int> data,
    Function(List<int>?, List<int>) receive, {
    int retry = 3,
    int timeout = 3000,
  }) async {
    requests.add(List.of(data));
    expect(retry, 1);
    expect(timeout, 3000);
    final buffer = <int>[];
    for (final chunk in replies.removeAt(0)) {
      final result = receive(chunk, buffer) as List<int>?;
      if (buffer.length > maxBuffered) maxBuffered = buffer.length;
      if (result != null) return result;
    }
    return null;
  }

  @override
  Future<bool> callWithoutRes(List<int> data) async {
    requests.add(List.of(data));
    return true;
  }
}

void main() {
  late _BleIo ble;
  late CanBleIo can;
  final response = ascii.encode('t58684340600101000200\r');
  final request = [0x40, 0x40, 0x60, 1, 0, 0, 0, 0];
  final payload = [0x43, 0x40, 0x60, 1, 1, 0, 2, 0];

  setUp(() {
    ble = _BleIo();
    can = CanBleIo(ble);
  });

  test(
    'complete response preserves request encoding and register values',
    () async {
      ble.replies.add([response]);
      expect(await can.upload(6, 0x6040, 1), [1, 0, 2, 0]);
      expect(ascii.decode(ble.requests.single), 't60684040600100000000\r');
    },
  );

  for (var split = 1; split < response.length; split++) {
    test('reassembles a response split after byte $split', () async {
      ble.replies.add([response.sublist(0, split), response.sublist(split)]);
      expect(await can.call(6, request), payload);
    });
  }

  test('empty notifications and byte-by-byte delivery are accepted', () async {
    ble.replies.add([
      [],
      for (final byte in response) [byte],
      [],
    ]);
    expect(await can.call(6, request), payload);
  });

  test(
    'acknowledgements and other nodes in the same notification are skipped',
    () async {
      ble.replies.add([
        ascii.encode('\r\nz\r\x07t58584340600103000400\r') +
            response +
            response,
      ]);
      expect(await can.call(6, request), payload);
    },
  );

  test('uppercase CAN ID and payload hex are accepted', () async {
    ble.replies.add([ascii.encode('t59A843406001ABCD0200\r')]);
    expect(await can.call(26, request), [
      0x43,
      0x40,
      0x60,
      1,
      0xab,
      0xcd,
      2,
      0,
    ]);
  });

  for (final invalid in [
    't586743406001010002\r',
    't5868434060010100020G\r',
    't58684340\r',
    't5868434060010100020000\r',
    't58684340',
    't5868${'0' * 10000}',
  ]) {
    test(
      'recovers after malformed or truncated frame (${invalid.length} bytes)',
      () async {
        ble.replies.add([ascii.encode(invalid), response]);
        expect(await can.call(6, request), payload);
        expect(ble.maxBuffered, lessThanOrEqualTo(21));
      },
    );
  }

  test('non-ASCII noise is ignored without a decoding exception', () async {
    ble.replies.add([
      [0xff, 0x74, 0xff, 0x0d],
      response,
    ]);
    expect(await can.call(6, request), payload);
  });

  test(
    'timeout reset discards a partial frame before the next attempt',
    () async {
      ble.replies.add([response.sublist(0, 10), null, response]);
      expect(await can.call(6, request), payload);
    },
  );

  test('wrong node and incomplete frames do not complete a request', () async {
    ble.replies.add([
      ascii.encode('t58584340600103000400\r'),
      response.sublist(0, 21),
    ]);
    expect(await can.call(6, request), isNull);
    ble.replies.add([response.sublist(21)]);
    expect(await can.call(6, request), isNull);
    ble.replies.add([response]);
    expect(await can.call(6, request), payload);
  });

  test('no notification returns no response', () async {
    ble.replies.add([]);
    expect(await can.call(6, request), isNull);
  });

  test(
    'segmented SDO upload reassembles each BLE-fragmented response',
    () async {
      for (final frame in [
        't5868414060010A000000\r',
        't58680001020304050607\r',
        't58681908090A00000000\r',
      ]) {
        final bytes = ascii.encode(frame);
        ble.replies.add([bytes.sublist(0, 20), bytes.sublist(20)]);
      }
      expect(await can.upload(6, 0x6040, 1), List.generate(10, (i) => i + 1));
      expect(ble.requests.map(ascii.decode), [
        't60684040600100000000\r',
        't60686000000000000000\r',
        't60687000000000000000\r',
      ]);
    },
  );

  test('expedited SDO download accepts a fragmented acknowledgement', () async {
    final ack = ascii.encode('t58686040600100000000\r');
    ble.replies.add([ack.sublist(0, 20), ack.sublist(20)]);
    expect(await can.download(6, 0x6040, 1, [1, 0]), isTrue);
    expect(ascii.decode(ble.requests.single), 't60682b40600101000000\r');
  });

  test('segmented SDO download retains its request sequence', () async {
    for (final frame in [
      't58686040600100000000\r',
      't58682000000000000000\r',
      't58683000000000000000\r',
    ]) {
      final bytes = ascii.encode(frame);
      ble.replies.add([bytes.sublist(0, 3), bytes.sublist(3)]);
    }
    expect(
      await can.download(6, 0x6040, 1, List.generate(10, (i) => i + 1)),
      isTrue,
    );
    expect(ble.requests.map(ascii.decode), [
      't6068214060010a000000\r',
      't60680001020304050607\r',
      't60681908090a00000000\r',
    ]);
  });

  test('SDO abort remains a failure', () async {
    final abort = ascii.encode('t58688040600100000206\r');
    ble.replies.add([abort.sublist(0, 20), abort.sublist(20)]);
    expect(await can.upload(6, 0x6040, 1), isNull);
  });

  for (final stale in [
    't58688000610101000405\r', // Actual trace: abort for 0x6100:01.
    't58688040600201000405\r', // Same index, different subindex.
    't586843006101DEADBEEF\r', // Successful response for another object.
    't586843406002DEADBEEF\r',
    't58686040600100000000\r', // Download acknowledgement during upload.
    't58680040600101000200\r', // Old segment, bytes happen to match index.
  ]) {
    test('upload skips stale response ${stale.trim()} in one notification',
        () async {
      ble.replies.add([ascii.encode(stale) + response]);
      expect(await can.upload(6, 0x6040, 1), [1, 0, 2, 0]);
      expect(ble.requests, hasLength(1));
    });
  }

  test('fragmented stale abort is skipped while valid header is retained',
      () async {
    final stale = ascii.encode('t58688000610101000405\r');
    ble.replies.add([
      stale.sublist(0, 12),
      stale.sublist(12) + response.sublist(0, 9),
      response.sublist(9),
    ]);
    expect(await can.upload(6, 0x6040, 1), [1, 0, 2, 0]);
    expect(ble.requests, hasLength(1));
  });

  test('only stale replies leave the request pending until timeout', () async {
    ble.replies.add([
      ascii.encode('t58688000610101000405\r'),
      ascii.encode('t586843406002DEADBEEF\r'),
      null,
    ]);
    expect(await can.upload(6, 0x6040, 1), isNull);
    expect(ble.requests, hasLength(1));
    ble.replies.add([response]);
    expect(await can.upload(6, 0x6040, 1), [1, 0, 2, 0]);
  });

  test('matching abort is not skipped in favor of a later success', () async {
    ble.replies.add([
      ascii.encode('t58688040600101000405\r') + response,
    ]);
    expect(await can.upload(6, 0x6040, 1), isNull);
  });

  for (final data in [
    [1, 0],
    List.generate(10, (i) => i + 1)
  ]) {
    test('download initiation filters stale replies (${data.length} bytes)',
        () async {
      ble.replies.add([
        ascii.encode('t58688000610101000405\r'
                't58686000610100000000\r'
                't58686040600200000000\r') +
            response + // Upload response for same object must not acknowledge write.
            ascii.encode('t58686040600100000000\r'),
      ]);
      if (data.length > 4) {
        ble.replies.add([ascii.encode('t58682000000000000000\r')]);
        ble.replies.add([ascii.encode('t58683000000000000000\r')]);
      }
      expect(await can.download(6, 0x6040, 1, data), isTrue);
      expect(ble.requests, hasLength(data.length > 4 ? 3 : 1));
    });
  }

  test('download matching abort remains a failure', () async {
    ble.replies.add([ascii.encode('t58688040600101000405\r')]);
    expect(await can.download(6, 0x6040, 1, [1, 0]), isFalse);
  });

  test('stale abort before segmented upload does not alter segment sequence',
      () async {
    ble.replies.add([
      ascii.encode('t58688000610101000405\r'
          't5868414060010A000000\r'),
    ]);
    ble.replies.add([ascii.encode('t58680001020304050607\r')]);
    ble.replies.add([ascii.encode('t58681908090A00000000\r')]);
    expect(await can.upload(6, 0x6040, 1), List.generate(10, (i) => i + 1));
    expect(ble.requests, hasLength(3));
  });

  test('block download sequence 0x40 is not treated as upload initiation',
      () async {
    for (final frame in [
      't5868A440600140000000\r', // Start: block size 64.
      't5868A240400000000000\r', // Acknowledge sequence 64 (0x40).
      't5868A201400000000000\r', // Last block: acknowledge sequence 1.
      't5868A100000000000000\r', // End acknowledgement.
    ]) {
      ble.replies.add([ascii.encode(frame)]);
    }
    expect(await can.blkDown(6, 0x6040, 1, List.filled(65 * 7, 0x55)), isTrue);
    expect(ble.requests, hasLength(67));
    expect(ascii.decode(ble.requests[64]), 't60684055555555555555\r');
  });

  test('write without response keeps its existing encoding', () async {
    expect(await can.callWithoutRes(6, request), isTrue);
    expect(ascii.decode(ble.requests.single), 't60684040600100000000\r');
  });
}
