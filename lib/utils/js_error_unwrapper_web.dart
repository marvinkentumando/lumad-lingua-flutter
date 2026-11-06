import 'dart:js_interop';

Object? unboxJavaScriptError(Object error) {
  try {
    final dynamic boxed = (error as dynamic).error;
    if (boxed.isA<JSBoxedDartObject>()) {
      return (boxed as JSBoxedDartObject).toDart;
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
