import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  static BuildContext? get context => navigatorKey.currentContext;

  // 推送新页面
  static Future<T?> push<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return navigator!.pushNamed<T>(routeName, arguments: arguments);
  }

  // 替换当前页面
  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    return navigator!.pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  // 推送并清除所有历史
  static Future<T?> pushAndClearStack<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return navigator!.pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  // 推送到指定页面并清除到该页面的历史
  static Future<T?> pushAndRemoveUntil<T extends Object?>(
    String routeName,
    String untilRouteName, {
    Object? arguments,
  }) {
    return navigator!.pushNamedAndRemoveUntil<T>(
      routeName,
      ModalRoute.withName(untilRouteName),
      arguments: arguments,
    );
  }

  // 返回上一页
  static void pop<T extends Object?>([T? result]) {
    return navigator!.pop<T>(result);
  }

  // 返回到指定页面
  static void popUntil(String routeName) {
    return navigator!.popUntil(ModalRoute.withName(routeName));
  }

  // 返回到根页面
  static void popToRoot() {
    return navigator!.popUntil((route) => route.isFirst);
  }

  // 显示对话框
  static Future<T?> showAppDialog<T>({
    required Widget child,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
  }) {
    return showDialog<T>(
      context: context!,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      builder: (context) => child,
    );
  }

  // 显示底部弹窗
  static Future<T?> showAppBottomSheet<T>({
    required Widget child,
    bool isScrollControlled = false,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
  }) {
    return showModalBottomSheet<T>(
      context: context!,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      builder: (context) => child,
    );
  }

  // 显示Snackbar
  static void showSnackBar({
    required String message,
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? textColor,
    SnackBarAction? action,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context!);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor),
        ),
        duration: duration,
        backgroundColor: backgroundColor,
        action: action,
      ),
    );
  }

  // 显示成功消息
  static void showSuccessMessage(String message) {
    showSnackBar(
      message: message,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  // 显示错误消息
  static void showErrorMessage(String message) {
    showSnackBar(
      message: message,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  // 显示警告消息
  static void showWarningMessage(String message) {
    showSnackBar(
      message: message,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );
  }

  // 显示信息消息
  static void showInfoMessage(String message) {
    showSnackBar(
      message: message,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
    );
  }

  // 显示确认对话框
  static Future<bool?> showConfirmDialog({
    required String title,
    required String content,
    String confirmText = '确定',
    String cancelText = '取消',
    Color? confirmColor,
  }) {
    return showAppDialog<bool>(
      child: AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => pop(true),
            style: confirmColor != null
                ? TextButton.styleFrom(foregroundColor: confirmColor)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  // 显示加载对话框
  static void showLoadingDialog({String? message}) {
    showAppDialog(
      barrierDismissible: false,
      child: AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(width: 16),
              Expanded(child: Text(message)),
            ],
          ],
        ),
      ),
    );
  }

  // 隐藏加载对话框
  static void hideLoadingDialog() {
    pop();
  }
}