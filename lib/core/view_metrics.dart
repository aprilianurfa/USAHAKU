import 'package:flutter/widgets.dart';

double getViewportScreenWidth(BuildContext context) {
  final view = View.of(context);
  return view.physicalSize.width / view.devicePixelRatio;
}

double getViewportScreenHeight(BuildContext context) {
  final view = View.of(context);
  return view.physicalSize.height / view.devicePixelRatio;
}

double getViewportKeyboardHeight(BuildContext context) {
  final view = View.of(context);
  return view.viewInsets.bottom / view.devicePixelRatio;
}

double getViewportTopPadding(BuildContext context) {
  final view = View.of(context);
  return view.padding.top / view.devicePixelRatio;
}

bool isViewportKeyboardVisible(BuildContext context) {
  return View.of(context).viewInsets.bottom > 0;
}
