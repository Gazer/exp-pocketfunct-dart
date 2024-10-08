import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:pocket_functions/pocket_functions.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

class EntryPoint {
  const EntryPoint();

  onRequest(Function(PocketRequest) req) async {
    final port = int.parse(Platform.environment['PORT'] ?? '8080');

    var handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler((Request r) async {
      var request = PocketRequest(
        path: r.url.path,
        httpMethod: r.method,
        body: await _readAsUint8List(r.read()),
        contentType: r.mimeType ?? "text/plain",
        params: r.url.queryParametersAll,
      );
      await req(request);
      return Response.ok(
        request.response.buffer.toString(),
        headers: request.response.headers,
      );
    });

    var server = await shelf_io.serve(handler, '0.0.0.0', port);

    // Enable content compression
    server.autoCompress = false;

    print('Serving at http://${server.address.host}:${server.port}');
  }

  listen(Function cb) async {
    cb();
    print('Process is listening for changes');
  }

  Future<Uint8List> _readAsUint8List(Stream<List<int>> stream) async {
    final List<int> data = await stream.expand((chunk) => chunk).toList();
    return Uint8List.fromList(data);
  }
}

const entryPoint = EntryPoint();
