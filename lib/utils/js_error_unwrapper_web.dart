import 'dart:js_interop';

Object? unboxJavaScriptError(Object error) {
  try {
    final dynamic boxed = (error as dynamic).error;
    if (boxed != null && boxed.isA<JSBoxedDartObject>()) {
      return (boxed as JSBoxedDartObject).toDart;
    }
  } catch (_) {}
  try {
    final dynamic jsError = error;
    final dynamic cause = jsError.cause;
    if (cause != null && cause.isA<JSBoxedDartObject>()) {
      return (cause as JSBoxedDartObject).toDart;
    }
  } catch (_) {}
  return null;
}

String? javascriptErrorStack(Object error) {
  try {
    final dynamic stack = (error as dynamic).stack;
    return stack is String ? stack : null;
  } catch (_) {}
  return null;
}

String? javascriptErrorDetails(Object error) {
  try {
    final dynamic jsError = error;
    final code = jsError.code;
    final message = jsError.message;
    final name = jsError.name;
    final details = <String>[
      if (name != null) name.toString(),
      if (code != null) 'code=$code',
      if (message != null) message.toString(),
    ];
    return details.isEmpty ? null : details.join(': ');
  } catch (_) {}
  return null;
}
