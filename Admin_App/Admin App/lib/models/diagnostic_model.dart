class DiagnosticModel {
  final int? id;
  final String? itemCode;
  final String category;
  final String testName;
  final String? parameter;
  final String? normalRange;
  final String? unit;
  final num? price;
  final String? notes;
  final bool? isActive;
  final String? image;

  DiagnosticModel({
    this.id,
    this.itemCode,
    required this.category,
    required this.testName,
    this.parameter,
    this.normalRange,
    this.unit,
    this.price,
    this.notes,
    this.isActive,
    this.image,
  });

  factory DiagnosticModel.fromJson(Map<String, dynamic> json) {
    return DiagnosticModel(
      id: json['id'],
      itemCode: json['item_code'],
      category: json['category'] ?? '',
      testName: json['test_name'] ?? '',
      parameter: json['parameter'],
      normalRange: json['normal_range'],
      unit: json['unit'],
      price: json['price'],
      notes: json['notes'],
      isActive: json['is_active'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (itemCode != null && itemCode!.isNotEmpty) 'item_code': itemCode,
      'category': category,
      'test_name': testName,
      if (parameter != null && parameter!.isNotEmpty) 'parameter': parameter,
      if (normalRange != null && normalRange!.isNotEmpty)
        'normal_range': normalRange,
      if (unit != null && unit!.isNotEmpty) 'unit': unit,
      if (price != null) 'price': price,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (image != null) 'image': image,
    };
  }
}

// One row per item_code (a test panel, e.g. CBC, groups many parameter
// rows that share the same item_code/category/test_name/price).
class DiagnosticGroupModel {
  final int id;
  final String? itemCode;
  final String category;
  final String testName;
  final num? price;
  final bool? isActive;
  final String? image;
  final int parameterCount;

  DiagnosticGroupModel({
    required this.id,
    this.itemCode,
    required this.category,
    required this.testName,
    this.price,
    this.isActive,
    this.image,
    required this.parameterCount,
  });

  factory DiagnosticGroupModel.fromJson(Map<String, dynamic> json) {
    return DiagnosticGroupModel(
      id: json['id'],
      itemCode: json['item_code'],
      category: json['category'] ?? '',
      testName: json['test_name'] ?? '',
      price: json['price'],
      isActive: json['is_active'],
      image: json['image'],
      parameterCount: json['parameterCount'] ?? 1,
    );
  }
}
