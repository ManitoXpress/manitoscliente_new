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
  String referrerUserId; // ID del trabajador que refirió
  String referralCode; // Código de referido ingresado por el usuario
  int points; // Cambiado a int

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
    required this.referrerUserId,
    required this.referralCode, // Agregamos el campo referralCode

    required this.points, // Agregamos el campo points

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
    required String referrerUserId,
    required String referralCode,
    required int points,
  }) : this(
    userId: userId,
    displayName: displayName,
    phoneNumber: phoneNumber,
    getToken: getToken,
    selectedCountryCode: selectedCountryCode,
    location: location,
    paymentType: paymentType,
    email: email,
    referrerUserId: referrerUserId,
    referralCode: referralCode,
    points: points,
    registrationData: RegistrationData(
      userId: userId,
      displayName: displayName,
      phoneNumber: phoneNumber,
      paymentType: paymentType,
      selectedCountryCode: selectedCountryCode,
      location: location,
      email: email, devicesId: '', fcmToken: '', points: 0,
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


          email: json['email'] ?? '', devicesId: '', fcmToken: '', points: json['points'] ?? 0,

        ), referrerUserId: json['referrerUserId'] ?? '', // ID del trabajador que refirió
        referralCode: json['referralCode'] ?? '', // Código de referido ingresado por el usuario
        points: json['points'] ?? 0, // Cambiado a int
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

          email: '', devicesId: '', fcmToken: '', points: 0,
        ), getToken: '', referrerUserId: '', referralCode: '', points: 0,
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