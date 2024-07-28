import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http; // Importa la biblioteca http
import 'dart:convert';

import 'package:rive/rive.dart';
import 'package:manitoscliente_new/home.dart';

import 'package:flutter/widgets.dart';
import 'package:manitoscliente_new/menu/Register.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginScreen> {
  late String animationURL;
  Artboard? _teddyArtboard;
  SMITrigger? successTrigger, failTrigger;
  SMIBool? isHandsUp, isChecking;
  SMINumber? numLook;
  void _navigateToProfilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  StateMachineController? stateMachineController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    animationURL = defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS
        ? 'assets/animations/login.riv'
        : 'animations/login.riv';
    rootBundle.load(animationURL).then(
      (data) {
        final file = RiveFile.import(data);
        final artboard = file.mainArtboard;
        stateMachineController =
            StateMachineController.fromArtboard(artboard, "State Machine 1");
        if (stateMachineController != null) {
          artboard.addController(stateMachineController!);

          stateMachineController!.inputs.forEach((e) {
            debugPrint(e.runtimeType.toString());
            debugPrint("name${e.name}End");
          });

          stateMachineController!.inputs.forEach((element) {
            if (element.name == "success") {
              successTrigger = element as SMITrigger;
            } else if (element.name == "fail") {
              failTrigger = element as SMITrigger;
            } else if (element.name == "hands_up") {
              isHandsUp = element as SMIBool;
            } else if (element.name == "idle") {
              isChecking = element as SMIBool;
            } else if (element.name == "Look_down_left") {
              numLook = element as SMINumber;
            }
          });
        }

        setState(() => _teddyArtboard = artboard);
      },
    );
  }

  void handsOnTheEyes() {
    isHandsUp?.change(true);
  }

  void lookOnTheTextField() {
    isHandsUp?.change(false);
    isChecking?.change(false);
    numLook?.change(
        1); //Ajusta este valor según cómo quieras que Teddy mire al campo de texto.
  }

  void moveEyeBalls(val) {
    numLook?.change(val.length.toDouble());
  }

  void login() {
    isChecking?.change(false);
    isHandsUp?.change(false);
    if (_emailController.text == "m1x3r" &&
        _passwordController.text == "1234") {
      successTrigger?.fire();
      _navigateToProfilePage(); // Redirige al perfil si la autenticación es exitosa
    } else {
      failTrigger?.fire();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Inicio de sesión fallido"),
            content: const Text(
                "Email o contraseña incorrectos. Inténtalo de nuevo."),
            actions: [
              TextButton(
                child: const Text("Aceptar"),
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
        title: const Text('Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        // Envolver el contenido en SingleChildScrollView
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_teddyArtboard != null)
                SizedBox(
                  width: 300,
                  height: 300,
                  child: Rive(
                    artboard: _teddyArtboard!,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              Container(
                alignment: Alignment.center,
                width: 500,
                padding:
                    const EdgeInsets.only(bottom: 30), // Padding aumentado aquí
                margin: const EdgeInsets.only(
                    bottom: 15 * 6), // Margen aumentado aquí

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Column(
                        children: [
                          const SizedBox(height: 15 * 2),
                          TextField(
                            controller: _emailController,
                            onTap: lookOnTheTextField,
                            onChanged: moveEyeBalls,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 14),
                            cursorColor: const Color(0xffb04863),
                            decoration: const InputDecoration(
                              hintText: "Email/Username",
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                              focusColor: Color(0xffb04863),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xffb04863),
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _passwordController,
                            onTap: handsOnTheEyes,
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: true,
                            style: const TextStyle(fontSize: 14),
                            cursorColor: const Color(0xffb04863),
                            decoration: const InputDecoration(
                              hintText: "Password",
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                              focusColor: Color(0xffb04863),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xffb04863),
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment
                                .spaceBetween, // Separa los elementos a los extremos
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: false,
                                    onChanged: (value) {},
                                  ),
                                  const Text(
                                    "Recuérdame",
                                    style: TextStyle(
                                      color: Color(0xFF000405),
                                      fontFamily:
                                          'Xpress Heavy', // Nombre de la fuente
                                      fontWeight: FontWeight.normal,
                                      fontStyle: FontStyle
                                          .italic, // Ajusta el color según tus necesidades
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    'No tienes cuenta aún? ',
                                    style: TextStyle(
                                      color: Color(0xFF000405),
                                      fontFamily:
                                          'Xpress Heavy', // Nombre de la fuente
                                      fontWeight: FontWeight.normal,
                                      fontStyle: FontStyle
                                          .italic, // Ajusta el color según tus necesidades
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                RegisterScreen()),
                                      );
                                    },
                                    child: Text(
                                      'Regístrate',
                                      style: TextStyle(
                                        color: Color(0xFF841813),
                                        fontFamily:
                                            'Xpress Heavy', // Nombre de la fuente
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FontStyle
                                            .italic, // Ajusta el color según tus necesidades
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          ElevatedButton(
                            onPressed: () {
                              _navigateToProfilePage();
                            },
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(
                                  const Color(0xFF1A819A)),
                              minimumSize:
                                  MaterialStateProperty.all(Size(150, 50)),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      30.0), // Hace que el botón sea ovalado
                                ),
                              ),
                              elevation: MaterialStateProperty.all(
                                  5), // Agrega sombreado
                              shadowColor: MaterialStateProperty.all(Colors
                                  .black38), // Define el color del sombreado
                            ),
                            child: const Text(
                              "INGRESAR",
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Xpress Heavy',
                                fontWeight: FontWeight.normal,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          const SizedBox(height: 8),
                          const Text(
                            'Inicie sesión con:',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Xpress Heavy',
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(
                              height:
                                  8), // Espacio entre el texto y los botones

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () {
                                  // Manejar inicio de sesión con Facebook aquí
                                },
                                icon: Icon(
                                  Icons.facebook,
                                  color: const Color(
                                      0xFF1A819A), // Color correspondiente al que tenía el botón anteriormente
                                  size: 40, // Aumentado el tamaño del ícono
                                ),
                              ),
                              SizedBox(
                                  width:
                                      20), // Espacio entre los botones, ajusta según prefieras
                              IconButton(
                                onPressed: () {
                                  // Manejar inicio de sesión con Google aquí
                                },
                                icon: Icon(
                                  Icons
                                      .egg_sharp, // Asegúrate de que este ícono sea el correcto para Google
                                  color: const Color(
                                      0xFF841813), // Color correspondiente al que tenía el botón anteriormente
                                  size: 40, // Aumentado el tamaño del ícono
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
