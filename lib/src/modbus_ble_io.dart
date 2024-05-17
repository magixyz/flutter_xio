

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:tuple/tuple.dart';

import 'utils/syncer.dart';
import 'modbus_ptl.dart';
import 'enum/register_type.dart';

class ModbusBleIo{

  FlutterReactiveBle ble;

  ModbusBleIo(this.ble);

  Future<Uint16List?> read(int slave, RegisterType rtype, int addr, int size,
    QualifiedCharacteristic writer,Function listen,
      {int retry = 5, int timeout = 500}) async {
    Uint8List data;
    switch (rtype) {
      case RegisterType.holding:
        data = ModbusPtl.readHoldingRegister(slave, addr, size);
        break;
      case RegisterType.input:
        data = ModbusPtl.readInputRegister(slave, addr, size);
        break;
      default:
        throw UnsupportedError('Unsupported register type: $rtype');
    }

    List<int>? ret = await call(data, writer, listen);

    if (ret == null) return null;

    Tuple3<int, int, Uint16List>? recv = ModbusPtl.r_modbus_read(Uint8List.fromList(ret!));

    return recv?.item3;

  }


  Future<int?>  write(int slave, Uint16List argData, int addr,
      QualifiedCharacteristic writer,Function listen,
      {int retry = 5, int timeout = 500}) async {
    Uint8List data = ModbusPtl.writeRegister(slave, addr, argData);

    List<int>? ret = await call(data, writer, listen);

    if (ret == null) return null;

    Tuple4<int, int, int, int>? recv = ModbusPtl.r_modbus_write(Uint8List.fromList(ret!));

    return recv?.item4;

  }



  Future<List<int>?> call(List<int> data,QualifiedCharacteristic writer,Function listen, {int retry = 3, int timeout = 500}) async {

    if (![0x00, 0x03, 0x04, 0x10].contains(data[1])) throw UnsupportedError('modbus function ${data[1]} not supported.');


    var syncer = Syncer<List<int>?>();

    List<int> recv = [];

    listen((event) {
      recv.addAll(event);

      if (recv.length < 3) return;

      if (recv[0] != data[0]) return;

      if (recv[1] == data[1] + 0x80) {
        syncer.onNotify(null);
        return;
      }

      if (recv[0] != data[0]) return;

      ByteData tmp = ByteData(data.length);
      for(int i=0; i<data.length; i++) tmp.setUint8(i, data[i]);

      if ([0x03,0x04].contains(recv[1])){
        if (recv.length < tmp.getUint16(4)*2 + 5) return;
      }else if([0x10].contains(recv[1])){
        if (recv.length < 8) return;
      }

      print('recv: $recv');

      syncer.onNotify(recv);

    });

    List<int>? ret = await syncer.sendRetryFor(() async {
      print('${DateTime.now()}, send: $data');

      recv.clear();

      await ble.writeCharacteristicWithoutResponse( writer, value: data);

      print('${DateTime.now()}, sent: $data');
    }, timeout: timeout, retry: retry);

    listen(null);

    return ret;
  }


}