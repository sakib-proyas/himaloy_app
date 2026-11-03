class ProductModel {
  final int id;
  final String name;
  final String? sku;
  final String? barcode;
  final double salePrice;
  final double wholesalePrice;
  final double purchasePrice;
  final String? packSize;
  final String? productGroup;
  final String? categoryName;
  final String? unitName;
  final double totalAvailableStock;

  ProductModel({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    required this.salePrice,
    required this.wholesalePrice,
    required this.purchasePrice,
    this.packSize,
    this.productGroup,
    this.categoryName,
    this.unitName,
    required this.totalAvailableStock,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      sku: json['sku'],
      barcode: json['barcode'],
      salePrice: double.tryParse(json['sale_price']?.toString() ?? '0') ?? 0.0,
      wholesalePrice: double.tryParse(json['wholesale_price']?.toString() ?? '0') ?? 0.0,
      purchasePrice: double.tryParse(json['purchase_price']?.toString() ?? '0') ?? 0.0,
      packSize: json['pack_size'],
      productGroup: json['product_group'],
      categoryName: json['category']?['name'],
      unitName: json['unit']?['name'],
      totalAvailableStock: double.tryParse(json['total_available_stock']?.toString() ?? '0') ?? 0.0,
    );
  }
}

