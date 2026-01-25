import 'package:flutter/widgets.dart';
import 'view_metrics.dart';

class ViewportUtils {
  static double getScreenWidth(BuildContext context) => getViewportScreenWidth(context);
  static double getScreenHeight(BuildContext context) => getViewportScreenHeight(context);
  static double getKeyboardHeight(BuildContext context) => getViewportKeyboardHeight(context);
  static double getTopPadding(BuildContext context) => getViewportTopPadding(context);
  static bool isKeyboardVisible(BuildContext context) => isViewportKeyboardVisible(context);
}
