

abstract class SdoIo{

  Future<List<int>?> call(int nodeId, List<int> data);
  Future<bool> callWithoutRes(int nodeId, List<int> data);

}