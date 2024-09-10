

import 'dart:async';
import 'dart:typed_data';

import 'package:tuple/tuple.dart';

import '../ble/ble_io.dart';
import '../utils/syncer.dart';
import 'modbus_ptl.dart';
import '../enum/register_type.dart';

class ModbusBleIoV2 {

  BleIo bleIo;


  ModbusBleIoV2(this.bleIo);

  Future<Uint16List?> read(int slave, RegisterType rtype, int addr, int size,
      {int retry = 3, int timeout = 1000}) async {
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

    List<int>? ret = await call(data);

    if (ret == null) return null;

    Tuple3<int, int, Uint16List>? recv = ModbusPtl.r_modbus_read(Uint8List.fromList(ret!));

    return recv?.item3;

  }


  Future<int?>  write(int slave, Uint16List argData, int addr,
      {int retry = 3, int timeout = 1000}) async {
    Uint8List data = ModbusPtl.writeRegister(slave, addr, argData);

    List<int>? ret = await call(data);

    if (ret == null) return null;

    Tuple4<int, int, int, int>? recv = ModbusPtl.r_modbus_write(Uint8List.fromList(ret!));

    return recv?.item4;

  }



  Future<List<int>?> call(List<int> data,{int retry = 3, int timeout = 1000}) async {
    List<int> sData = data;

    List<int>? rData = await bleIo.call(
        sData, (List<int> nData, List<int> rData) {
      rData.addAll(nData);

      if (rData.length < 3) return null;

      if (rData[0] != data[0]) return null;

      if (rData[1] == data[1] + 0x80) {
        return null;
      }

      if (rData[1] != data[1]) return null;

      ByteData tmp = ByteData(data.length);
      for (int i = 0; i < data.length; i++)
        tmp.setUint8(i, data[i]);

      if ([0x03, 0x04].contains(rData[1])) {
        if (rData.length < tmp.getUint16(4) * 2 + 5) return null;
      } else if ([0x10].contains(rData[1])) {
        if (rData.length < 8) return null;
      }


      return rData;
    });

    return rData;
  }


}