import 'package:equatable/equatable.dart';

/// Branch entity from the GuestDataForChrome API response
class Branch extends Equatable {
  final String name;
  final String address;
  final String city;
  final String state;
  final String district;
  final String pinCode;
  final String phone;
  final String email;

  // FRRO-specific overrides
  final String addressInIndia; // AddressInIndia — reference address in India
  final int
  fromGuestAddressInIndia; // 0 = use branch address, 1 = use guest address
  final String contactPhoneInIndia; // ContactPhoneInIndia
  final String mobileInIndia; // MobileInIndia

  const Branch({
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.district,
    required this.pinCode,
    required this.phone,
    required this.email,
    required this.addressInIndia,
    required this.fromGuestAddressInIndia,
    required this.contactPhoneInIndia,
    required this.mobileInIndia,
  });

  /// The effective reference address to use in the FRRO form.
  /// Uses [addressInIndia] if set, otherwise falls back to [address].
  String get effectiveAddressInIndia =>
      addressInIndia.isNotEmpty ? addressInIndia : address;

  /// The effective phone to use in the FRRO form.
  String get effectivePhone =>
      contactPhoneInIndia.isNotEmpty ? contactPhoneInIndia : phone;

  static const empty = Branch(
    name: '',
    address: '',
    city: '',
    state: '',
    district: '',
    pinCode: '',
    phone: '',
    email: '',
    addressInIndia: '',
    fromGuestAddressInIndia: 0,
    contactPhoneInIndia: '',
    mobileInIndia: '',
  );

  @override
  List<Object?> get props => [
    name,
    address,
    city,
    state,
    district,
    pinCode,
    phone,
    email,
    addressInIndia,
    fromGuestAddressInIndia,
    contactPhoneInIndia,
    mobileInIndia,
  ];
}
