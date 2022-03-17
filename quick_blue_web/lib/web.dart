library quick_blue_web;

export 'src/quick_blue_web_unsupported.dart'
    if (dart.library.html) 'src/quick_blue_web.dart';
