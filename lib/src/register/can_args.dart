
class CanArgs{
  late int mIndex;
  late int sIndex;

  CanArgs(this.mIndex,this.sIndex);

  CanArgs.load(Map<String,dynamic> json){
    mIndex = json['m_index'];
    sIndex = json['s_index'];
  }
}