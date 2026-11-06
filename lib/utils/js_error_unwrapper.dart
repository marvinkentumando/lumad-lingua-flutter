import 'js_error_unwrapper_stub.dart'
    if (dart.library.js_interop) 'js_error_unwrapper_web.dart' as platform;

Object? unboxJavaScriptError(Object error) =>
    platform.unboxJavaScriptError(error);

String? javascriptErrorStack(Object error) =>
    platform.javascriptErrorStack(error);
