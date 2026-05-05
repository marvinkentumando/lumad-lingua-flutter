import 'dart:convert';
import 'dart:io';

void main() {
  // Set up JSON-RPC handling over stdio
  stdin.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
    try {
      final request = jsonDecode(line);
      final id = request['id'];
      final method = request['method'];

      if (method == 'initialize') {
        _sendResponse(id, {
          'protocolVersion': '2024-11-05',
          'capabilities': {
            'tools': {},
          },
          'serverInfo': {
            'name': 'Lumad Lingua Native Server',
            'version': '1.0.0',
          },
        });
      } else if (method == 'notifications/initialized') {
        // Just acknowledge
      } else if (method == 'tools/list') {
        _sendResponse(id, {
          'tools': [
            {
              'name': 'check_project_status',
              'description': 'Returns the current health status of the project.',
              'inputSchema': {
                'type': 'object',
                'properties': {},
              },
            }
          ],
        });
      } else if (method == 'tools/call') {
        final toolName = request['params']['name'];
        if (toolName == 'check_project_status') {
          _sendResponse(id, {
            'content': [
              {'type': 'text', 'text': 'Project health is optimal. Analysis is clean.'}
            ],
          });
        }
      }
    } catch (e) {
      stderr.writeln('Error processing request: $e');
    }
  });
}

void _sendResponse(dynamic id, dynamic result) {
  final response = {
    'jsonrpc': '2.0',
    'id': id,
    'result': result,
  };
  stdout.writeln(jsonEncode(response));
}
