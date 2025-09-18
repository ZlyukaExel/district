import 'package:district/services/tcp_client.dart';
import 'package:district/services/tcp_server.dart';

class TcpTransport {
  final TcpServer server = TcpServer();
  final TcpClient client = TcpClient();

  Future<int> startServer() async {
    return await server.startServer();
  }

  void startClient(int port) {
    client.startClient(port);
  }
}
