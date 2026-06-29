import 'dart:io';

class _AllowAllCerts extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void applyHttpOverrides() {
  HttpOverrides.global = _AllowAllCerts();
}
