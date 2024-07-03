
class HexUtil{
  static List<int> hex2byte(String hex){
    List<int> ret = [];
    for (int i=0; i< hex.length/2; i++){
      ret.add(int.parse(hex.substring(i*2,i*2+2),radix: 16));
    }
    return ret;
  }

  static String byte2hex(List<int> vs){
    return vs.map((e) => e.toRadixString(16).padLeft(2,'0')).join();
  }
}