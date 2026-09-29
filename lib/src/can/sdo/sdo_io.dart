

abstract class SdoIo{

  Future<List<int>?> call(int nodeId, List<int> data);
  // Only normal upload/download initiation carries an object address.
  // Transports may filter stale replies before completing the receive wait.
  Future<List<int>?> callInitial(int nodeId, List<int> data) => call(nodeId, data);

  Future<bool> callWithoutRes(int nodeId, List<int> data);

}