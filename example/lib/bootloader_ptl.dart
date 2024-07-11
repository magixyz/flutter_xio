
import 'dart:typed_data';

import 'iap_ptl.dart';


class BootloaderPtl{
  static Uint16List iapEnterBootloader(){
    return IapPtl.iapByte2register(IapPtl.iap(0x70,0x30,0x00,Uint8List.fromList([0,0,0,0x08])));
  }

  static Uint16List iapExitBootloader(Uint8List addr){
    return IapPtl.iapByte2register(IapPtl.iap(0x71,0x30,0x00,addr));
  }

  static Uint16List iapBootloaderReset(){
    return IapPtl.iapByte2register(Uint8List.fromList([0xaa,0x55]));
  }
  static Uint16List iapBootloaderJump(){
    return IapPtl.iapByte2register(Uint8List.fromList([0x55,0xaa]));
  }
}