import 'package:district/tcp_client.dart';
import 'package:district/tcp_server.dart';

class TcpTransport {
  final TcpServer server = TcpServer();
  final TcpClient client = TcpClient();

  Future<void> startServer(Function(int) onPortAssigned) async {
    await server.startServer(onPortAssigned);
  }

  void startClient(int port) {
    client.startClient(port);
  }
}
