
import 'dart:async';

class Syncer<T>{

  Completer<T?> completer = Completer<T?>();
  Timer? timer;
  bool _breaked = false;

  Future<T?> sendRetryFor(Function func, {int retry=3,int timeout=1000}) async{

    _breaked = false;


    for (int i=0; i< retry; i++){


      print('retry: $i / $retry');

      if (_breaked) return null;

      var ret = await sendWaitFor(func, timeout:timeout);

      print('${DateTime.now()}, ret:$ret');

      if (ret != null) return ret;

    }

    print('Retry failed ...');

    return null;
  }

  Future<T?> sendWaitFor(Function func, {int timeout=1000}) async{

    completer = Completer<T?>();

    var tmpCompleter = completer;


    print('${DateTime.now()}, call send func');
    try{
      await func();
    }catch(e) {
      print('try-catch error : $e');

      return null;
    }
    timer = Timer(Duration(milliseconds: timeout),()  {

      print('${DateTime.now()}, Timer actived..');
      if (!tmpCompleter.isCompleted){
        print('Wait timeout ..'); // Prints after 1 second.
        print('${tmpCompleter == this.completer}');
        tmpCompleter.complete(null);
      }

    });

    var ok = await completer.future;

    if (timer!=null) {
      if (timer!.isActive) timer?.cancel();
      timer = null;
    }

    return ok;

  }

  onNotify(T t){
    if (!completer.isCompleted){
      completer.complete(t);
    }else{
      print('completer completed ...');
    }
  }

  close() {
    _breaked = true;
    if (timer != null && timer!.isActive) timer!.cancel();
    if (!completer.isCompleted) completer.complete(null);
  }


}