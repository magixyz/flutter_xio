
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_xio/flutter_xio.dart';
import 'package:provider/provider.dart';

import 'bootloader_ptl.dart';

class DeviceBleWidget extends StatefulWidget {

  DiscoveredDevice discoveredDevice;

  DeviceBleWidget(this.discoveredDevice, {super.key});

  @override
  State<DeviceBleWidget> createState() => _DeviceBleWidgetState();
}

class _DeviceBleWidgetState extends State<DeviceBleWidget> {


  late BleDeviceConnector connector = Provider.of<BleDeviceConnector>(context,listen: false);

  Characteristic? controlC;
  Characteristic? dataC;
  // CanBleIo? canBleIo;
  // BleIo? bleIo;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    Future.delayed(Duration(seconds: 1),()async{

      print('connecting:');

       var ret = await connector.connect(widget.discoveredDevice.id);

       print('connect: $ret');

       if (ret){
          List<Characteristic?>? cs = await connector.discovery(Uuid.parse('1D14D6EE-FD63-4FA1-BFA4-8F47B42119F0'),
             [Uuid.parse('F7BF3564-FB6D-4E53-88A4-5E37E0326063'),Uuid.parse('984227F3-34FC-4045-A5D0-2C581F81A153')]);

          controlC = cs?[0];
          dataC = cs?[1];


          // if (reader!= null){
          //
          //   print( 'reader: ${reader?.id}');
          //   print( 'reader: ${reader?.isNotifiable}');
          //   print( 'reader: ${reader?.isReadable}');
          //   print( 'reader: ${reader?.isWritableWithResponse}');
          //   reader?.subscribe().listen((event) {
          //     print('event: $event');
          //
          //
          //     var str = String.fromCharCodes(event);
          //
          //     print('event str:  $str');
          //
          //
          //   });
          // }

       }
    });

  }

  @override
  Widget build(BuildContext context) {

    return Consumer<DeviceConnectionState>(builder:(_, deviceConnectionState ,__){


      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.discoveredDevice.name),
        ),
        body: ListView(

          children: [
            ListTile(
              title: Text(widget.discoveredDevice.name),
              subtitle: Text(widget.discoveredDevice.id),
              trailing: Builder(builder: (BuildContext context) {
                switch(deviceConnectionState){
                  case DeviceConnectionState.disconnected:
                    return Text('Disconnected');
                  case DeviceConnectionState.connected:
                    return Text('Connected');
                  case DeviceConnectionState.connecting:
                    return Text('Connecting');
                  case DeviceConnectionState.disconnecting:
                    return Text('Disconnecting');
                  default:
                    return Text('Unknown');
                }
              },

              ),
            ),
            ListTile(title: Builder(builder: (context){
              if (deviceConnectionState == DeviceConnectionState.disconnected)
                return Text('Connect');
              else if (deviceConnectionState == DeviceConnectionState.connected)
                return Text('Disconnect');
              else
                return Text(deviceConnectionState.name);
            },) ,onTap:[DeviceConnectionState.disconnected,DeviceConnectionState.connected].contains(deviceConnectionState)?()async{
              if (deviceConnectionState == DeviceConnectionState.disconnected){
                await connector.connect(widget.discoveredDevice.id);
              }else if (deviceConnectionState == DeviceConnectionState.connected){
                await connector.disconnect();
              }
            }:null,trailing: Icon(Icons.keyboard_return_outlined),),

            ListTile(title: Text('ble control start'),onTap: ()async{

              controlC?.write([0]);

              print('control data writed..');

            },),
            ListTile(title: Text('can ble blk down'),onTap: ()async{
              DefaultAssetBundle.of(context).load('assets/dfu.bin').then((v)async {

                var bytes = v.buffer.asInt8List();

                int limit = 256 + 128;
                int cursor = 0;
                while (cursor < bytes.length){
                  if (bytes.length - cursor < limit) limit = bytes.length - cursor;
                  var wd = bytes.sublist(cursor,cursor + limit);
                  print('write: ${wd}');
                  await dataC?.write(wd);

                  cursor += limit;
                  print('Writing data: ${(cursor/ bytes.length)}' );
                }

              });


            },),
            ListTile(title: Text('ble control end'),onTap: ()async{


              controlC?.write([3]);

            },),
          ],
        ),
      );

    });



  }

  @override
  void dispose() async{
    // TODO: implement dispose
    super.dispose();

    if (connector != null ){
      await connector.disconnect();
    }
  }

}
