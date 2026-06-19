import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

class AppShortcuts {
  static bool get _isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  static Widget wrap({
    required Widget child,
    Map<ShortcutActivator, VoidCallback>? bindings,
  }) {
    if (!_isDesktop) return child;
    final allBindings = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.escape): () {},
      if (bindings != null) ...bindings,
    };
    return CallbackShortcuts(
      bindings: allBindings,
      child: Focus(autofocus: true, child: child),
    );
  }

  static Widget wrapWithOverrides({
    required Widget child,
    required Map<ShortcutActivator, VoidCallback> bindings,
  }) {
    if (!_isDesktop) return child;
    return CallbackShortcuts(
      bindings: bindings,
      child: Focus(autofocus: true, child: child),
    );
  }
}
