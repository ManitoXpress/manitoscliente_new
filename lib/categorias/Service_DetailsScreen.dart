import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manitoscliente_new/controller/RegisController.dart';
import 'package:manitoscliente_new/request/ResponseGet.dart';
import 'package:manitoscliente_new/request/dataprofile.dart';
import 'package:manitoscliente_new/utils/validation.dart';
import '../categorias/terms.dart';

import '../Styles/stilo.dart';
import '../home.dart';
import '../controller/auth_utils.dart';
import '../request/ResponsePost.dart';
import '../request/resquest.dart';
import '../utils/compres.dart';
import '../utils/status.dart';
import '../wizards/datalocation.dart';
import '../wizards/dataservice.dart';
import '../wizards/datetime.dart';
import 'package:intl/intl.dart';


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ServiceFormPage extends StatefulWidget {
  final ServiceRequest serviceRequest;
  final bool acceptTerms;
  late final List<ServiceRequest> serviceRequests;
  final DateTime? selectedDate;
  final String selectedTime;
  final String selectedServiceTitle;
  final String token;
  final String categoryId;
  final String expertiseId;
  final String expertiseName;
  final UserData userData;

  ServiceFormPage({
    Key? key,
    required this.serviceRequest,
    required this.acceptTerms,
    required this.serviceRequests,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedServiceTitle,
    required this.token,
    required this.categoryId,
    required this.expertiseId,
    required this.expertiseName,
    required this.userData,
  }) : super(key: key);

  @override
  _ServiceFormPageState createState() => _ServiceFormPageState();
}


class _ServiceFormPageState extends State<ServiceFormPage> {
  int currentStep = 0;
  late ServiceDataWizard dataWizard;
  late TermsAndConditionsWizard termsWizard;
  late final LocationAndFavoritesWizard locationAndFavoritesWizard;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Estados locales para fecha y hora
  DateTime? pickedDate;
  TimeOfDay? pickedTime;

  String? token;
  String? fcmToken;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();

    AuthUtils.getToken().then((value) => setState(() => token = value));
    FirebaseMessaging.instance.getToken().then((value) => setState(() => fcmToken = value));

    // Inicializar estados locales con valores pasados
    pickedDate = widget.selectedDate;
    try {
      final dt = DateTime.parse(widget.selectedTime).toLocal();
      pickedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    } catch (_) {
      pickedTime = null;
    }

    dataWizard = ServiceDataWizard(
      selectedServiceTitle: widget.selectedServiceTitle,
      serviceRequest: widget.serviceRequest,
      onImageSelected: (image) {
        if (image != null && widget.serviceRequest.images.length < 3) {
          setState(() => widget.serviceRequest.images.add(image as String));
        }
      },
      onPriceSelected: (price) {
        widget.serviceRequest.offeredPrice = price as double;
      },
      onNextStep: () {},
      services: widget.serviceRequests,
      maxImageCount: 3,
    );

    locationAndFavoritesWizard = LocationAndFavoritesWizard(
      location: widget.serviceRequest.location,
      onLocationSelected: (loc) => setState(() {
        widget.serviceRequest.location = {'lat': loc.latitude, 'lng': loc.longitude};
      }),
      onFavoritesSelected: (fav) => setState(() => widget.serviceRequest.isFavorite = fav),
      onNextStep: () {},
    );

    termsWizard = TermsAndConditionsWizard(
      isChecked: false,
      onAcceptTerms: (accepted) => widget.serviceRequest.acceptedTerms = accepted,
      onNextStep: () {},
    );
  }

  void onSubmit() async {
  // 0) Obtener el usuario actual
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    _showError('Usuario no autenticado.');
    return;
  }

  // 1) Bloquear a invitados
  if (user.isAnonymous) {
    _showRegisterRequiredDialog();
    return;
  }

  // 2) Términos y token
  if (!widget.acceptTerms || token == null || isSubmitting) {
    _showError('Términos no aceptados o token nulo.');
    return;
  }

  // 3) Fecha y hora
  if (pickedDate == null || pickedTime == null) {
    _showError('Por favor selecciona fecha y hora.');
    return;
  }

  final dateOnly = DateFormat('yyyy-MM-dd').format(pickedDate!);
  final timeOnly = pickedTime!.format(context);

  // 4) Mostrar loader
  setState(() => isSubmitting = true);
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Enviando datos…')
          ],
        ),
      ),
    ),
  );

  try {
    // 5) Armar la petición
    widget.serviceRequest
      ..userId = user.uid
      ..status = StatusUtils.getStatusById('available');

    final expertisesJson = jsonEncode(
      widget.serviceRequest.expertises.map((e) => e.toMap()).toList(),
    );

    List<String> imageUrls = [];
    for (final path in widget.serviceRequest.images) {
      if (path.isEmpty) continue;
      final file = File(path);
      final compressed = await compressAndResizeImage(file);
      final url = await ApiService().uploadImageToFirebaseStorage(compressed, user.uid);
      imageUrls.add(url);
    }

    final devicesId = await AuthUtils.getDeviceId();
    final authToken = await AuthUtils.getToken();

    final response = await ApiService().sendDataToBackend(
      widget.serviceRequest,
      authToken!,
      widget.serviceRequest.status.id,
      expertisesJson,
      widget.categoryId,
      widget.expertiseId,
      widget.serviceRequest.status,
      widget.expertiseName,
      imageUrls,
      devicesId,
      fcmToken,
      dateOnly,
      timeOnly,
    );

    // 6) Ocultar loader
    Navigator.of(context).pop();
    if (response.statusCode == 201) {
      _showSuccess();
    } else {
      _showError('Código: ${response.statusCode}');
    }
  } catch (e) {
    Navigator.of(context).pop();
    _showError(e.toString());
  } finally {
    setState(() => isSubmitting = false);
  }
}

// Diálogo para invitar al registro cuando el usuario es anónimo
void _showRegisterRequiredDialog() {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Registro Requerido', style: MyTextStyles.drawerButtonTextStyle3),
      content: Text(
        'Para solicitar un servicio debes crear una cuenta. ¿Quieres registrarte ahora?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RegistrationScreen(
                  registrationController: RegistrationController(),
                  completeRegistrationCallback: () {},
                  apiService2: ApiService2(),
                ),
              ),
            );
          },
          child: const Text('Registrarme'),
        ),
      ],
    ),
  );
}


  void _showSuccess() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          '¡Éxito!',
          style: MyTextStyles.welcomeTotheJungle,
        ),
        content: const Text(
          'Servicio creado correctamente.',
          style: MyTextStyles.formServiceTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => HomeScreen(
                  initialPageIndex: 2,
                  userData: widget.userData,
                ),
              ),
                  (_) => false,
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1A819A),
              backgroundColor: const Color(0xFFE8E8E8),
              padding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(
                color: Color(0xFFE8E8E8),
                width: 1,
              ),
            ),
            child: Text(
              'Ir a Historial',
              style: MyTextStyles.welcomeTotheJungle,
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Generamos el wizard inline para reflejar pickedDate/pickedTime actualizados
    final dateTimeWizard = DateTimeSelectionWizard(
      selectedDate: pickedDate,
      selectedTime: pickedTime,
      onDateSelected: (date) => setState(() => pickedDate = date),
      onTimeSelected: (time) => setState(() => pickedTime = time),
      onNextStep: () {},
    );

    return Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Formulario de Servicio', style: MyTextStyles.buttonTextStyle),
        ),
        body: Stepper(
            type: StepperType.vertical,
            currentStep: currentStep,
            onStepContinue: () {
              if (currentStep < 2) setState(() => currentStep++);
              else onSubmit();
            },
            onStepCancel: () {
              if (currentStep > 0) setState(() => currentStep--);
            },
            controlsBuilder: (context, details) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentStep > 0)
                  ElevatedButton(
                    onPressed: details.onStepCancel,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF830A09)),
                    child: const Text('Cancelar', style: MyTextStyles.drawerButtonLabelTextStyle),
                  ),
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A819A)),
                  child: const Text('Continuar', style: MyTextStyles.drawerButtonLabelTextStyle),
                ),
              ],
            ),
            steps: [
              Step(
                title: const Text('Datos del servicio', style: MyTextStyles.drawerButtonTextStyle3),
                content: dataWizard,
                isActive: currentStep >= 0,
                state: currentStep > 0 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('Fecha y hora', style: MyTextStyles.drawerButtonTextStyle3),
                content: dateTimeWizard,
                isActive: currentStep >= 1,
                state: currentStep > 1 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('Ubicación', style: MyTextStyles.drawerButtonTextStyle3),
                content: locationAndFavoritesWizard,
                isActive: currentStep >= 2,
                state: currentStep > 2 ? StepState.complete : StepState.indexed,
              ),
            ],
            stepIconBuilder: (i, state) => CircleAvatar(
              backgroundColor: const Color(0xFF1A819A),
              child: Text('${i+1}', style: MyTextStyles.tabTextStyle1),
            ),
            ),
        );
    }
}