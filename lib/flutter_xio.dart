library flutter_xio;

export 'src/enum/byte_loc.dart';
export 'src/enum/register_type.dart';
export 'src/modbus_ptl.dart';
export 'src/register_cluster.dart';
export 'src/register_field.dart';
export 'src/modbus_ble_io.dart';
export 'src/utils/syncer.dart';

export 'src/ble/ble_device_connector.dart';
export 'src/ble/ble_device_interactor.dart';
export 'src/ble/ble_scanner.dart';
export 'src/ble/reactive_state.dart';

/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;
}
