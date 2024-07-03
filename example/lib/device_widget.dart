
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_xio/flutter_xio.dart';
import 'package:provider/provider.dart';

class DeviceWidget extends StatefulWidget {

  DiscoveredDevice discoveredDevice;

  DeviceWidget(this.discoveredDevice, {super.key});

  @override
  State<DeviceWidget> createState() => _DeviceWidgetState();
}

class _DeviceWidgetState extends State<DeviceWidget> {


  late BleDeviceConnector connector = Provider.of<BleDeviceConnector>(context,listen: false);

  Characteristic? writer;
  Characteristic? reader;
  CanBleIo? canBleIo;
  BleIo? bleIo;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    Future.delayed(Duration(seconds: 1),()async{

      print('connecting:');

       var ret = await connector.connect(widget.discoveredDevice.id);

       print('connect: $ret');

       if (ret){
          List<Characteristic?>? cs = await connector.discovery(Uuid.parse('07F30001-2864-41B5-B8C6-02081F7BFA46'),
             [Uuid.parse('07F300C1-2864-41B5-B8C6-02081F7BFA46'),Uuid.parse('07F30041-2864-41B5-B8C6-02081F7BFA46')]);

          reader = cs?[0];
          writer = cs?[1];


          if (reader != null && writer != null){

            bleIo = BleIo(reader!, writer!, connector);
            canBleIo = CanBleIo(bleIo!);


          }


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
            ListTile(title: Text('MTU'),onTap: ()async{
              var data = List<int>.of(utf8.encode('S8\r'));
              await writer?.write(data);
              print('write: $data');
            },),
            ListTile(title: Text('Open'),onTap: ()async{
              var data = List<int>.of(utf8.encode('O\r'));
              await writer?.write(data);
              print('write: $data');
            },),
            ListTile(title: Text('Close'),onTap: ()async{
              var data = List<int>.of(utf8.encode('C\r'));
              await writer?.write(data);
              print('write: $data');
            },),
            ListTile(title: Text('Read'),onTap: ()async{
              // var data = List<int>.of(utf8.encode('t60684000600100000000\r'));
              var data = List<int>.of(utf8.encode('t60684000610100000000\r'));
              await writer?.write(data);

              print('write: $data');
            },),
            ListTile(title: Text('can ble upload'),onTap: ()async{

              List<int>? ret = await canBleIo?.upload(6, 0x60c0, 0x01);


              print('>>>>>>>> upload: ${ HexUtil.byte2hex(ret??[])}');

            },),
            ListTile(title: Text('can ble download'),onTap: ()async{

              bool? ret = await canBleIo?.download(6, 0x60c0, 0x01, HexUtil.hex2byte('b80b2c01d007e803d007e803b80be02ee8030000b80b2c01d007e803d007e803b80be02ee8030000b80b2c01d007e803d007e803b80be02ee8030000b80b2c01d007e803d007e803b80be02ee8030000b80b2c01d007e803d007e803b80be02ee8030000dc052c01e8032003e803e803b80be02ee8030000'));


              print('>>>>>>>> download: ${ ret }');

            },)
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
