class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final bool isAdmin;
  final EmployeeModel? employee;
  final List<String> permissions;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isAdmin,
    this.employee,
    this.permissions = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {List<String>? permissions, EmployeeModel? employee}) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      isAdmin: json['is_admin'] ?? false,
      employee: employee,
      permissions: permissions ?? [],
    );
  }
}

class EmployeeModel {
  final int id;
  final String? employeeId;
  final String name;
  final String? designation;
  final String? territory;
  final String? region;
  final String? phone;
  final int? warehouseId;
  final String? warehouseName;

  EmployeeModel({
    required this.id,
    this.employeeId,
    required this.name,
    this.designation,
    this.territory,
    this.region,
    this.phone,
    this.warehouseId,
    this.warehouseName,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'],
      name: json['name'] ?? '',
      designation: json['designation'],
      territory: json['territory'],
      region: json['region'],
      phone: json['phone'],
      warehouseId: json['warehouse_id'],
      warehouseName: json['warehouse']?['name'],
    );
  }
}

