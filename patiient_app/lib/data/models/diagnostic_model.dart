// A single diagnostic_data row — one parameter within a test panel, or the
// diagnostic snapshot attached to a booking (`booking.diagnostic`).
class DiagnosticModel {
  final int id;
  final String? itemCode;
  final String testName;
  final String category;
  final String? parameter;
  final String? normalRange;
  final String? unit;
  final double price;
  final String? notes;
  final String? image;
  final bool isActive;

  DiagnosticModel({
    required this.id,
    this.itemCode,
    required this.testName,
    required this.category,
    this.parameter,
    this.normalRange,
    this.unit,
    required this.price,
    this.notes,
    this.image,
    this.isActive = true,
  });

  factory DiagnosticModel.fromJson(Map<String, dynamic> json) {
    return DiagnosticModel(
      id: json['id'] as int? ?? 0,
      itemCode: json['item_code'] as String?,
      testName: json['test_name'] as String? ?? 'Test',
      category: json['category'] as String? ?? '',
      parameter: json['parameter'] as String?,
      normalRange: json['normal_range'] as String?,
      unit: json['unit'] as String?,
      price: json['price'] is String
          ? (double.tryParse(json['price']) ?? 0)
          : ((json['price'] as num?) ?? 0).toDouble(),
      notes: json['notes'] as String?,
      image: json['image'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (itemCode != null) 'item_code': itemCode,
      'test_name': testName,
      'category': category,
      if (parameter != null) 'parameter': parameter,
      if (normalRange != null) 'normal_range': normalRange,
      if (unit != null) 'unit': unit,
      'price': price,
      if (notes != null) 'notes': notes,
      if (image != null) 'image': image,
      'is_active': isActive,
    };
  }

  // The backend has no separate "department" column — category doubles as
  // it for the older booking screens that still read this field.
  String get department => category;

  // The backend has no separate description/preparation columns; kept as
  // always-null so booking screens that conditionally show them compile
  // and simply never render that section (unchanged from prior behavior).
  String? get description => null;
  String? get preparation => null;

  String get priceText => '৳${price.toStringAsFixed(0)}';
}

// One parameter row within a test panel's details table
// (Parameter / Normal Range / Unit).
class DiagnosticParameterModel {
  final int id;
  final String? parameter;
  final String? normalRange;
  final String? unit;
  final String? notes;

  DiagnosticParameterModel({
    required this.id,
    this.parameter,
    this.normalRange,
    this.unit,
    this.notes,
  });

  factory DiagnosticParameterModel.fromJson(Map<String, dynamic> json) {
    return DiagnosticParameterModel(
      id: json['id'] as int? ?? 0,
      parameter: json['parameter'] as String?,
      normalRange: json['normal_range'] as String?,
      unit: json['unit'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

// One card on the diagnostic list screen — one entry per unique item_code
// (a test panel such as CBC groups every parameter row that shares it).
class DiagnosticGroupModel {
  final int id;
  final String? itemCode;
  final String testName;
  final String category;
  final double price;
  final String? image;
  final int parameterCount;

  DiagnosticGroupModel({
    required this.id,
    this.itemCode,
    required this.testName,
    required this.category,
    required this.price,
    this.image,
    required this.parameterCount,
  });

  factory DiagnosticGroupModel.fromJson(Map<String, dynamic> json) {
    return DiagnosticGroupModel(
      id: json['id'] as int? ?? 0,
      itemCode: json['item_code'] as String?,
      testName: json['test_name'] as String? ?? 'Test',
      category: json['category'] as String? ?? '',
      price: json['price'] is String
          ? (double.tryParse(json['price']) ?? 0)
          : ((json['price'] as num?) ?? 0).toDouble(),
      image: json['image'] as String?,
      parameterCount: (json['parameterCount'] as num?)?.toInt() ?? 1,
    );
  }

  String get priceText => '৳${price.toStringAsFixed(0)}';

  String get parameterCountText =>
      '$parameterCount ${parameterCount == 1 ? 'Parameter' : 'Parameters'}';
}

// Full payload for the Diagnostic Details screen: panel summary plus every
// parameter row belonging to the selected item_code.
class DiagnosticDetailModel {
  final int id;
  final String? itemCode;
  final String testName;
  final String category;
  final double price;
  final String? image;
  final String? notes;
  final int parameterCount;
  final List<DiagnosticParameterModel> parameters;

  DiagnosticDetailModel({
    required this.id,
    this.itemCode,
    required this.testName,
    required this.category,
    required this.price,
    this.image,
    this.notes,
    required this.parameterCount,
    required this.parameters,
  });

  factory DiagnosticDetailModel.fromJson(Map<String, dynamic> json) {
    final params = (json['parameters'] as List? ?? const [])
        .map((p) => DiagnosticParameterModel.fromJson(p as Map<String, dynamic>))
        .toList();
    return DiagnosticDetailModel(
      id: json['id'] as int? ?? 0,
      itemCode: json['item_code'] as String?,
      testName: json['test_name'] as String? ?? 'Test',
      category: json['category'] as String? ?? '',
      price: json['price'] is String
          ? (double.tryParse(json['price']) ?? 0)
          : ((json['price'] as num?) ?? 0).toDouble(),
      image: json['image'] as String?,
      notes: json['notes'] as String?,
      parameterCount: (json['parameterCount'] as num?)?.toInt() ?? params.length,
      parameters: params,
    );
  }

  // Built from a DiagnosticGroupModel when a panel has no item_code, so the
  // details screen can still render without a second network round-trip.
  factory DiagnosticDetailModel.fromGroup(DiagnosticGroupModel group) {
    return DiagnosticDetailModel(
      id: group.id,
      itemCode: group.itemCode,
      testName: group.testName,
      category: group.category,
      price: group.price,
      image: group.image,
      notes: null,
      parameterCount: 1,
      parameters: const [],
    );
  }

  String get priceText => '৳${price.toStringAsFixed(0)}';

  String get parameterCountText =>
      '$parameterCount ${parameterCount == 1 ? 'Parameter' : 'Parameters'}';
}
