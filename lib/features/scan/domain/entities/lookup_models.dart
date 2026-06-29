class VisaType {
  final String visaId;
  final String visaTypeName;

  const VisaType({required this.visaId, required this.visaTypeName});

  factory VisaType.fromJson(Map<String, dynamic> json) => VisaType(
    visaId: json['visaid'] ?? '',
    visaTypeName: json['visatype'] ?? '',
  );
}

class VisaSubType {
  final String visaSubTypeId;
  final String visaSubType;
  final String visaTypeId;
  final String visaSubTypeShort;

  const VisaSubType({
    required this.visaSubTypeId,
    required this.visaSubType,
    required this.visaTypeId,
    required this.visaSubTypeShort,
  });

  factory VisaSubType.fromJson(Map<String, dynamic> json) => VisaSubType(
    visaSubTypeId: json['VisaSubTypeId'] ?? '',
    visaSubType: json['VisaSubType'] ?? '',
    visaTypeId: json['VisaTypeId'] ?? '',
    visaSubTypeShort: json['VisaSubTypeShort'] ?? '',
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

class IndianDistrict {
  final String
  districtRecId; // FrroDistrictRecId (numeric, used in SavePassportAndVisa)
  final String
  districtId; // FrroDistrictId (alphanumeric, used in FRRO form selects)
  final String districtName;
  final String stateId;

  const IndianDistrict({
    required this.districtRecId,
    required this.districtId,
    required this.districtName,
    required this.stateId,
  });

  factory IndianDistrict.fromJson(Map<String, dynamic> json) => IndianDistrict(
    districtRecId: json['FrroDistrictRecId']?.toString() ?? '',
    districtId: json['FrroDistrictId'] ?? '',
    districtName: json['FrroDistrict'] ?? '',
    stateId: json['zs_stateid'] ?? '',
  );
}
