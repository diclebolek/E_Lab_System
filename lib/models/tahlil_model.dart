class TahlilModel {
  final String id;
  final String fullName;
  final String tcNumber;
  final DateTime? birthDate;
  final int age;
  final String gender;
  final String patientType;
  final String sampleType;
  final List<SerumType> serumTypes;
  final String reportDate;

  TahlilModel({
    required this.id,
    required this.fullName,
    required this.tcNumber,
    this.birthDate,
    required this.age,
    required this.gender,
    required this.patientType,
    required this.sampleType,
    required this.serumTypes,
    required this.reportDate,
  });

  factory TahlilModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return TahlilModel(
      id: docId,
      fullName: data['fullName'] ?? '',
      tcNumber: data['tcNumber'] ?? '',
      birthDate: data['birthDate'] is DateTime
          ? data['birthDate']
          : (data['birthDate'] != null
                ? DateTime.parse(data['birthDate'].toString())
                : null),
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      patientType: data['patientType'] ?? '',
      sampleType: data['sampleType'] ?? '',
      serumTypes:
          (data['serumTypes'] as List<dynamic>?)
              ?.map((e) => SerumType.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      reportDate: data['reportDate'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'tcNumber': tcNumber,
      'birthDate': birthDate,
      'age': age,
      'gender': gender,
      'patientType': patientType,
      'sampleType': sampleType,
      'serumTypes': serumTypes.map((e) => e.toMap()).toList(),
      'reportDate': reportDate,
    };
  }
}

class SerumType {
  final String type;
  final String value;

  SerumType({required this.type, required this.value});

  factory SerumType.fromMap(Map<String, dynamic> map) {
    return SerumType(type: map['type'] ?? '', value: map['value'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'type': type, 'value': value};
  }
}
