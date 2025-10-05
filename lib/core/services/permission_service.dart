import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../errors/app_exceptions.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  static PermissionService get instance => _instance;
  PermissionService._internal();

  // 检查传感器权限状态
  Future<bool> checkSensorPermissions() async {
    try {
      // 检查加速度计和陀螺仪权限（在Android上通常不需要特殊权限）
      // 但在某些设备或系统版本上可能需要
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Android平台通常不需要特殊的传感器权限
        return true;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS平台也通常不需要特殊的传感器权限
        return true;
      }
      return true;
    } catch (e) {
      throw PermissionException('检查传感器权限失败', originalError: e);
    }
  }

  // 请求传感器权限
  Future<bool> requestSensorPermissions() async {
    try {
      // 在大多数情况下，传感器权限是自动获得的
      // 这里主要是为了未来扩展和特殊情况处理
      return await checkSensorPermissions();
    } catch (e) {
      throw PermissionException('请求传感器权限失败', originalError: e);
    }
  }

  // 检查存储权限（用于保存运动数据和导出功能）
  Future<bool> checkStoragePermission() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.storage.status;
        return status.isGranted;
      }
      return true; // iOS通常不需要存储权限
    } catch (e) {
      throw PermissionException('检查存储权限失败', originalError: e);
    }
  }

  // 请求存储权限
  Future<bool> requestStoragePermission() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
      return true;
    } catch (e) {
      throw PermissionException('请求存储权限失败', originalError: e);
    }
  }

  // 检查通知权限
  Future<bool> checkNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      throw PermissionException('检查通知权限失败', originalError: e);
    }
  }

  // 请求通知权限
  Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      throw PermissionException('请求通知权限失败', originalError: e);
    }
  }

  // 检查所有必要权限
  Future<Map<String, bool>> checkAllPermissions() async {
    try {
      final results = <String, bool>{};
      
      results['sensor'] = await checkSensorPermissions();
      results['storage'] = await checkStoragePermission();
      results['notification'] = await checkNotificationPermission();
      
      return results;
    } catch (e) {
      throw PermissionException('检查权限失败', originalError: e);
    }
  }

  // 请求所有必要权限
  Future<Map<String, bool>> requestAllPermissions() async {
    try {
      final results = <String, bool>{};
      
      results['sensor'] = await requestSensorPermissions();
      results['storage'] = await requestStoragePermission();
      results['notification'] = await requestNotificationPermission();
      
      return results;
    } catch (e) {
      throw PermissionException('请求权限失败', originalError: e);
    }
  }

  // 获取权限状态描述
  String getPermissionStatusDescription(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return '已授权';
      case PermissionStatus.denied:
        return '已拒绝';
      case PermissionStatus.restricted:
        return '受限制';
      case PermissionStatus.limitedDenied:
        return '有限拒绝';
      case PermissionStatus.permanentlyDenied:
        return '永久拒绝';
      default:
        return '未知状态';
    }
  }

  // 检查权限是否被永久拒绝
  Future<bool> isPermissionPermanentlyDenied(Permission permission) async {
    try {
      final status = await permission.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      return false;
    }
  }

  // 打开应用设置页面
  Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      throw PermissionException('打开应用设置失败', originalError: e);
    }
  }

  // 显示权限解释对话框
  Future<bool> shouldShowPermissionRationale(Permission permission) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return await permission.shouldShowRequestRationale;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // 获取权限状态信息
  Future<Map<String, dynamic>> getPermissionInfo() async {
    try {
      final info = <String, dynamic>{};
      
      // 传感器权限信息
      info['sensor'] = {
        'hasPermission': await checkSensorPermissions(),
        'description': '访问设备传感器以检测运动',
        'required': true,
      };
      
      // 存储权限信息
      final storageStatus = await Permission.storage.status;
      info['storage'] = {
        'hasPermission': storageStatus.isGranted,
        'status': getPermissionStatusDescription(storageStatus),
        'isPermanentlyDenied': storageStatus.isPermanentlyDenied,
        'description': '保存运动记录和导出数据',
        'required': false,
      };
      
      // 通知权限信息
      final notificationStatus = await Permission.notification.status;
      info['notification'] = {
        'hasPermission': notificationStatus.isGranted,
        'status': getPermissionStatusDescription(notificationStatus),
        'isPermanentlyDenied': notificationStatus.isPermanentlyDenied,
        'description': '发送运动提醒和成就通知',
        'required': false,
      };
      
      return info;
    } catch (e) {
      throw PermissionException('获取权限信息失败', originalError: e);
    }
  }
}