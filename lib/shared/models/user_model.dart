import 'package:uuid/uuid.dart';

class UserModel {
  final String localUserId;
  final String? username;
  final int? age;
  final String? gender;
  final double? height; // cm
  final double? weight; // kg
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    String? localUserId,
    this.username,
    this.age,
    this.gender,
    this.height,
    this.weight,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : localUserId = localUserId ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  UserModel copyWith({
    String? localUserId,
    String? username,
    int? age,
    String? gender,
    double? height,
    double? weight,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      localUserId: localUserId ?? this.localUserId,
      username: username ?? this.username,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'local_user_id': localUserId,
      'username': username,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      localUserId: map['local_user_id'] as String,
      username: map['username'] as String?,
      age: map['age'] as int?,
      gender: map['gender'] as String?,
      height: map['height'] as double?,
      weight: map['weight'] as double?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory UserModel.fromJson(Map<String, dynamic> json) => fromMap(json);

  @override
  String toString() {
    return 'UserModel(localUserId: $localUserId, username: $username, age: $age, gender: $gender, height: $height, weight: $weight, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.localUserId == localUserId &&
        other.username == username &&
        other.age == age &&
        other.gender == gender &&
        other.height == height &&
        other.weight == weight &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return localUserId.hashCode ^
        username.hashCode ^
        age.hashCode ^
        gender.hashCode ^
        height.hashCode ^
        weight.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  // 计算BMI
  double? get bmi {
    if (height == null || weight == null) return null;
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  // 获取BMI状态描述
  String get bmiStatus {
    final bmiValue = bmi;
    if (bmiValue == null) return '未知';
    
    if (bmiValue < 18.5) return '体重过轻';
    if (bmiValue < 24) return '正常体重';
    if (bmiValue < 28) return '超重';
    return '肥胖';
  }

  // 计算基础代谢率 (BMR)
  double? get bmr {
    if (age == null || height == null || weight == null || gender == null) {
      return null;
    }

    // Mifflin-St Jeor方程
    double baseBmr = (10 * weight!) + (6.25 * height!) - (5 * age!);
    
    if (gender!.toLowerCase() == 'male' || gender!.toLowerCase() == '男') {
      return baseBmr + 5;
    } else {
      return baseBmr - 161;
    }
  }

  // 获取个人化卡路里系数
  double get personalCalorieMultiplier {
    double multiplier = 1.0;
    
    // 体重系数
    if (weight != null) {
      multiplier *= weight! / 70.0; // 标准体重70kg
    }
    
    // 年龄系数
    if (age != null) {
      if (age! < 25) {
        multiplier *= 1.1;
      } else if (age! > 45) {
        multiplier *= 0.9;
      }
    }
    
    // 性别系数
    if (gender != null) {
      if (gender!.toLowerCase() == 'female' || gender!.toLowerCase() == '女') {
        multiplier *= 0.85;
      }
    }
    
    return multiplier;
  }
}