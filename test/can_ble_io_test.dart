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

  test('write without response keeps its existing encoding', () async {
    expect(await can.callWithoutRes(6, request), isTrue);
    expect(ascii.decode(ble.requests.single), 't60684040600100000000\r');
  });
}
