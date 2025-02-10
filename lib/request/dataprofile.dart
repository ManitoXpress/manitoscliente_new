import '../metodos/RegisController.dart';

class UserData {
  String userId;
  String displayName;
  String phoneNumber;
  String selectedCountryCode;
  final String? getToken;
  Map<String, double?>? location;
  String paymentType;
  String email;

  RegistrationData registrationData; // Nueva propiedad

  UserData({
    required this.userId,
    required this.displayName,
    required this.phoneNumber,
    required this.selectedCountryCode,
    required this.location,
    required this.paymentType,
    required this.getToken,
    required this.email,

    required this.registrationData, // Nueva propiedad
  });

  UserData.fromForm({
    required String userId,
    required String displayName,
    required String phoneNumber,
    required String getToken,
    required String pdfPath,
    required String selectedCountryCode,
    required Map<String, double?>? location,
    required String paymentType,
    required String email,
  }) : this(
    userId: userId,
    displayName: displayName,
    phoneNumber: phoneNumber,
    getToken: getToken,
    selectedCountryCode: selectedCountryCode,
    location: location,
    paymentType: paymentType,
    email: email,
    registrationData: RegistrationData(
      userId: userId,
      displayName: displayName,

      phoneNumber: phoneNumber,
      paymentType: paymentType,

      selectedCountryCode:selectedCountryCode,

      location: location,

      email: email, devicesId: '', fcmToken: '',

    ),
  );


  factory UserData.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('email')) {
      String paymentType = json['paymentType'] is String ? json['paymentType'] : '';

      return UserData(
        userId: json['id'] ?? '',
        displayName: json['displayName'] ?? '',
        email: json['email'] ?? '',
        phoneNumber: json['phoneNumber'] ?? '',
        getToken: json['getToken']?? '',
        paymentType: paymentType,
        selectedCountryCode: json['selectedCountryCode']?? '',
        location: json['location'] != null
            ? Map<String, double?>.from(json['location'])
            : null,
        registrationData: RegistrationData.fromForm(
          userId: json['id'] ?? '',
          displayName: json['displayName'] ?? '',
          phoneNumber: json['phoneNumber'] ?? '',
          paymentType: paymentType,
          selectedCountryCode: json['selectedCountryCode']?? '',
          location: json['location'] != null
              ? Map<String, double?>.from(json['location'])
              : null,


          email: json['email'] ?? '', devicesId: '', fcmToken: '',

        ),
      );
    } else {
      return UserData(
        userId: '',
        displayName: '',
        email: '',
        phoneNumber: '',
        selectedCountryCode: '',
        location: {},
        paymentType: '',
        registrationData: RegistrationData(
          userId: '',
          displayName: '',

          selectedCountryCode: '',
          phoneNumber: '',
          paymentType: '',

          location: {},

          email: '', devicesId: '', fcmToken: '',
        ), getToken: '',
      );
    }
  }

  static List<String> _convertToList(dynamic value) {
    if (value is List<dynamic>) {
      return value.map((dynamic item) => item.toString()).toList();
    } else if (value is String) {
      return [value];
    } else {
      return [];
    }
  }
}