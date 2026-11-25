class MedicineModel {
  final int sl;
  final String company;
  final String tradeName;
  final String genericNameWithStrength;
  final String dosageForm;
  final String darNo;

  const MedicineModel({
    required this.sl,
    required this.company,
    required this.tradeName,
    required this.genericNameWithStrength,
    required this.dosageForm,
    required this.darNo,
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) => MedicineModel(
    sl: (json['sl'] as num).toInt(),
    company: json['company']?.toString() ?? '',
    tradeName: json['trade_name']?.toString() ?? '',
    genericNameWithStrength:
        json['generic_name_with_strength']?.toString() ?? '',
    dosageForm: json['dosage_form']?.toString() ?? '',
    darNo: json['dar_no']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'company': company.trim(),
    'trade_name': tradeName.trim(),
    'generic_name_with_strength': genericNameWithStrength.trim(),
    'dosage_form': dosageForm.trim(),
    'dar_no': darNo.trim(),
  };
}
