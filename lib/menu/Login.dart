import 'dart:convert';
import 'package:rive/rive.dart' as rive;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:manitoscliente_new/ServicesResponse/ResponseGet.dart';
import 'package:manitoscliente_new/ServicesResponse/resquest.dart';
import 'package:manitoscliente_new/menu/Register.dart';
import 'package:manitoscliente_new/metodos/animationcontroller.dart';
import 'package:manitoscliente_new/metodos/logincontroller.dart';
import 'package:rive/rive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ServicesResponse/dataprofile.dart';
import '../Styles/stilo.dart';
import '../home.dart';
import '../metodos/RegisController.dart';
import '../widgets/welcome.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginScreen> {
  late String animationURL;
  rive.Artboard? _teddyArtboard;
  rive.SMITrigger? successTrigger, failTrigger;
  rive.SMIBool? isHandsUp, isChecking;
  rive.SMINumber? numLook;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  List<ServiceRequest> serviceRequests = [];
  bool isPasswordVisible = false;

  rive.StateMachineController? stateMachineController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final loginController = LoginScreenController();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _navigateToCardScreenPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  Future<void> fetchData(String userId, String token) async {
    try {
      String column = "serviceType";
      String value = "pipe-repair";
      String type = "match";

      final response = await ApiService2()
          .getByUserId(userId, token, column, value, type);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          serviceRequests =
              data.map((item) => ServiceRequest.fromSnapshot(item)).toList();
        });
      } else {
        print(
            'Error al obtener datos del backend. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en la solicitud HTTP: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    animationURL = defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS
        ? 'assets/animations/login.riv'
        : 'animations/login.riv';
    rootBundle.load(animationURL).then(
      (data) {
        final file = rive.RiveFile.import(data);
        final artboard = file.mainArtboard;
        stateMachineController =
            rive.StateMachineController.fromArtboard(artboard, "State Machine 1");
        if (stateMachineController != null) {
          artboard.addController(stateMachineController!);

          stateMachineController!.inputs.forEach((element) {
            switch (element.name) {
              case "success":
                successTrigger = element as rive.SMITrigger;
                break;
              case "fail":
                failTrigger = element as rive.SMITrigger;
                break;
              case "hands_up":
                isHandsUp = element as rive.SMIBool;
                break;
              case "idle":
                isChecking = element as rive.SMIBool;
                break;
              case "Look_down_left":
                numLook = element as rive.SMINumber;
                break;
              default:
                break;
            }
          });
        }

        setState(() => _teddyArtboard = artboard);
      },
    );
  }

  Future<void> login() async {
    isChecking?.change(false);
    isHandsUp?.change(false);
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Verificar si el usuario existe en la colección 'workers'
      print("Intentando obtener el documento del usuario con UID: ${userCredential.user?.uid}");
      final userDoc = await _firestore.collection('workers').doc(userCredential.user?.uid).get();

      if (userDoc.exists) {
        print("Usuario encontrado en la colección de 'workers'.");
        successTrigger?.fire();
        _navigateToCardScreenPage(); // Redirige al perfil si la autenticación es exitosa
      } else {
        print("Usuario no encontrado en la colección de 'workers'.");
        failTrigger?.fire();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Usuario no encontrado"),
              content: Text("El usuario no existe en la colección de workers."),
              actions: [
                TextButton(
                  child: Text("Aceptar"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print("Error al iniciar sesión: $e");
      failTrigger?.fire();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Inicio de sesión fallido"),
            content: Text("Email o contraseña incorrectos. Inténtalo de nuevo."),
            actions: [
              TextButton(
                child: Text("Aceptar"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffd6e2ea),
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              child: Container(
                padding: EdgeInsets.all(10.w),
                constraints: BoxConstraints(maxWidth: 0.2.sw),
                child: Image.asset(
                  'assets/images/LOGO1_Blanco.png',
                  width: 0.2.sw,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              'ManitoXpress',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Xpress Heavy',
                fontWeight: FontWeight.normal,
                fontStyle: FontStyle.italic,
                fontSize: 20.sp,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: 1.sw,
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_teddyArtboard != null)
                  SizedBox(
                    width: 0.8.sw,
                    height: 0.38.sh,
                    child: rive.Rive(
                      artboard: _teddyArtboard!,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                SizedBox(height: 10.h),
                Text(
                  'Bienvenidos a Manitos Xpress',
                  style: MyTextStyles.buttonTextStyle3,
                ),
                SizedBox(height: 10.h),
                TextButton(
                  onPressed: () {
                    launch('https://manitoxpress-cf855.web.app/#/PrivacyPage');
                  },
                  child: Text(
                    'Términos y Condiciones de Manitos Xpress',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
                SizedBox(height: 30.h),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.email),
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 20.h),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock),
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: false,
                          onChanged: (value) {},
                        ),
                        const Text("Recuerdame"),
                      ],
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1A819A),
                            padding: EdgeInsets.all(7.w),
                          ),
                          child: const Text("INGRESAR"),
                        ),
                        SizedBox(width: 20.w),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RegisterScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1A819A),
                            padding: EdgeInsets.all(7.w),
                          ),
                          child: Text("Registrarse"),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                
                TextButton(
                  onPressed: () async {
                    final url = 'https://manitoxpress-cf855.web.app/#/DeletePage';
                    if (await canLaunch(url)) {
                      await launch(url);
                    } else {
                      print('No se pudo abrir el enlace: $url');
                    }
                  },
                  child: Text(
                    'Borrar Cuenta',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}