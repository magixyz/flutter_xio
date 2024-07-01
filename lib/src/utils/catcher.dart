
class Catcher{

  static T? call<T>(Function func){
    try{
      return func();

    }catch(e){
      print('exception: $e');
      return null;
    }

  }

}