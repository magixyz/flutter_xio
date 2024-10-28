library flutter_xio;

import 'dart:convert';

import 'package:crclib/catalog.dart';

export 'src/enum/byte_loc.dart';
export 'src/enum/register_type.dart';

export 'src/register/register_cluster.dart';
export 'src/register/register_field.dart';
export 'src/register/can_args.dart';

export 'src/modbus/modbus_ptl.dart';
export 'src/modbus/modbus_ble_io.dart';
export 'src/modbus/modbus_ble_io_v2.dart';

export 'src/utils/syncer.dart';
export 'src/utils/hex_util.dart';

export 'src/ble/ble_device_connector.dart';
export 'src/ble/ble_scanner.dart';
export 'src/ble/reactive_state.dart';
export 'src/ble/ble_status_monitor.dart';
export 'src/ble/ble_logger.dart';
export 'src/ble/ble_io.dart';

export 'src/can/can_ble_io.dart';
export 'src/can/blecan_ptl.dart';

export 'src/rpc/rpc_ptl.dart';
export 'src/rpc/rpc_ble_io.dart';

/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;
}

