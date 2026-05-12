class VisaType {
  final String visaId;
  final String visaTypeName;

  const VisaType({required this.visaId, required this.visaTypeName});

  factory VisaType.fromJson(Map<String, dynamic> json) => VisaType(
    visaId: json['visaid'] ?? '',
    visaTypeName: json['visatype'] ?? '',
  );
}

class Purpose {
  final String purposeId;
  final String purposeName;

  const Purpose({required this.purposeId, required this.purposeName});

  factory Purpose.fromJson(Map<String, dynamic> json) => Purpose(
    purposeId: json['purposefrroid'] ?? '',
    purposeName: json['purposeofvisit'] ?? '',
  );
}

class MrzCountry {
  final String code;
  final String name;

  const MrzCountry({required this.code, required this.name});

  factory MrzCountry.fromJson(Map<String, dynamic> json) => MrzCountry(
    code: json['zs_nationalitycode'] ?? '',
    name: json['zs_nationality'] ?? '',
  );
}

class VehicleType {
  final int vehicleTypeId;
  final String vehicleTypeName;

  const VehicleType({
    required this.vehicleTypeId,
    required this.vehicleTypeName,
  });

  factory VehicleType.fromJson(Map<String, dynamic> json) => VehicleType(
    vehicleTypeId: json['VehicleTypeId'] is int
        ? json['VehicleTypeId']
        : int.tryParse(json['VehicleTypeId'].toString()) ?? 0,
    vehicleTypeName: json['VehicleTypeName'] ?? '',
  );
}

class IndianState {
  final String stateId;
  final String stateName;

  const IndianState({required this.stateId, required this.stateName});

  factory IndianState.fromJson(Map<String, dynamic> json) => IndianState(
    stateId: json['zs_stateid'] ?? '',
    stateName: json['zs_statename'] ?? '',
  );
}
