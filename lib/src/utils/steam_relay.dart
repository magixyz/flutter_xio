
import 'dart:async';

// import 'package:ZecMobility/utils/log_util.dart';

class StreamRelay<T>{

  final _streamController = StreamController<T>();
  Stream<T> get stream => _streamController.stream;
  T? current;

  void relay(T t){

    _streamController.add(t);
    current = t;

    // LogUtil.logger.d('stream relay: $t');
  }


}