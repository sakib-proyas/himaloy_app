class CustomerModel {
  final int id;
  final String? customerId;
  final String name;
  final String? proprietorName;
  final String? customerCategory;
  final String phone;
  final String? phone2;
  final String? address;
  final String? region;
  final String? territory;
  final double totalDue;
  final bool isWholesale;

  CustomerModel({
    required this.id,
    this.customerId,
    required this.name,
    this.proprietorName,
    this.customerCategory,
    required this.phone,
    this.phone2,
    this.address,
    this.region,
    this.territory,
    required this.totalDue,
    required this.isWholesale,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] ?? 0,
      customerId: json['customer_id'],
      name: json['name'] ?? '',
      proprietorName: json['proprietor_name'],
      customerCategory: json['customer_category'],
      phone: json['phone'] ?? '',
      phone2: json['phone2'],
      address: json['address'],
      region: json['region'],
      territory: json['territory'],
      totalDue: double.tryParse(json['total_due']?.toString() ?? '0') ?? 0.0,
      isWholesale: json['is_wholesale'] ?? false,
    );
  }
}

