class DueInvoiceModel {
  final int id;
  final String invoiceNo;
  final String date;
  final String warehouseName;
  final double total;
  final double paid;
  final double due;
  final String status;

  DueInvoiceModel({
    required this.id,
    required this.invoiceNo,
    required this.date,
    required this.warehouseName,
    required this.total,
    required this.paid,
    required this.due,
    required this.status,
  });

  factory DueInvoiceModel.fromJson(Map<String, dynamic> json) {
    return DueInvoiceModel(
      id: json['id'] ?? 0,
      invoiceNo: json['invoice_no'] ?? '',
      date: json['date'] ?? '',
      warehouseName: json['warehouse_name'] ?? 'Main Warehouse',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      paid: double.tryParse(json['paid']?.toString() ?? '0') ?? 0.0,
      due: double.tryParse(json['due']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'due',
    );
  }
}

