
import 'dart:async';

class SyncerV1<T>{

  Function sender;
  Function recver;


  Completer<T?> _completer = Completer<T?>();
  Timer? timer;
  bool _breaked = false;

  SyncerV1(this.sender,this.recver);

  Future<T?> retry({int retry=3,int timeout=1000}) async{

    _breaked = false;


    for (int i=0; i< retry; i++){


      print('retry: $i / $retry');

      if (_breaked) return null;

      var ret = await call(timeout:timeout);

      print('${DateTime.now()}, ret:$ret');

      if (ret != null) return ret;

    }

    print('Retry failed ...');

    return null;
  }

  Future<T?> call({int timeout=1000}) async{

    _completer = Completer<T?>();

    // print('${DateTime.now()}, sync_v1 call');
    try{
      await sender();
    }catch(e) {

      print('try-catch error : $e');

      return null;
    }
    timer = Timer(Duration(milliseconds: timeout),()  {

      print('${DateTime.now()}, Timer actived.. timeout:${timeout}');
      if (!_completer.isCompleted){
        _completer.complete(null);
      }
    });

    var ok = await _completer.future;

    if (timer!=null) {
      if (timer!.isActive) timer?.cancel();
      timer = null;
    }

    return ok;

  }

  notify(T t)async{
    try{
      var ret = await recver(t);
      if (ret != null){
        if (!_completer.isCompleted) {
          _completer.complete(ret);
        }
      }
    }catch(e){
      if (!_completer.isCompleted) {
        _completer.complete(null);
      }
    }
  }



}