import 'package:flutter/material.dart';
import 'package:searchbar_animation/searchbar_animation.dart';

import '../Styles/stilo.dart';

class HelpScreen extends StatefulWidget {
  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final List<Faq> faqs = [
    Faq(
      question: '¿Cómo funciona la aplicación?',
      answer:
          'La aplicación te permite solicitar servicios de mano de obra a través de una plataforma en línea. Simplemente regístrate, explora los servicios disponibles y elige el que necesites. Luego, selecciona un proveedor de servicios y coordina los detalles con ellos.',
    ),
    Faq(
      question:
          '¿Qué tipos de servicios de mano de obra se ofrecen en la aplicación?',
      answer:
          'Nuestra aplicación ofrece una amplia gama de servicios de mano de obra, que incluyen plomería, electricidad, carpintería, pintura, jardinería, limpieza, reparaciones domésticas, instalaciones y muchos otros. ¡Estamos aquí para ayudarte con tus necesidades de mano de obra!',
    ),
    Faq(
      question: '¿Cómo elijo al proveedor de servicios adecuado?',
      answer:
          'Nuestra aplicación te muestra perfiles detallados de los proveedores de servicios, que incluyen información sobre su experiencia, calificaciones y reseñas de clientes anteriores. Puedes comparar y elegir al proveedor de servicios que mejor se adapte a tus necesidades y presupuesto.',
    ),
    Faq(
      question: '¿Cómo se calcula el costo de los servicios?',
      answer:
          'El costo de los servicios de mano de obra puede variar según la naturaleza del trabajo, la ubicación y otros factores. Los proveedores de servicios establecen sus propias tarifas, y podrás verlas en sus perfiles. Algunos proveedores también pueden ofrecer cotizaciones personalizadas para proyectos específicos.',
    ),
    Faq(
      question: '¿Cómo se coordina la fecha y hora del servicio?',
      answer:
          'Una vez que hayas seleccionado a un proveedor de servicios, podrás comunicarte directamente con ellos a través de la aplicación para coordinar la fecha y hora que te convenga. Podrás discutir los detalles y acordar una cita conveniente para ambas partes.',
    ),
    Faq(
      question: '¿Cómo puedo pagar por los servicios?',
      answer:
          'Actualmente, ofrecemos opciones de pago en línea a través de tarjetas de crédito o débito. Algunos proveedores también pueden aceptar pagos en efectivo, pero eso deberá ser acordado directamente con el proveedor de servicios.',
    ),
    Faq(
      question:
          '¿Qué debo hacer en caso de que haya un problema con el servicio?',
      answer:
          'Si encuentras algún problema con el servicio recibido, te recomendamos comunicarte directamente con el proveedor de servicios para resolver el problema. También puedes contactar a nuestro equipo de soporte, y estaremos encantados de ayudarte a encontrar una solución satisfactoria.',
    ),
  ];
  TextEditingController _textEditingController = TextEditingController();
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    _textEditingController.addListener(() {
      setState(() {
        _showClearButton = _textEditingController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ayuda',
          style: MyTextStyles.buttonTextStyle,
        ),
        backgroundColor: const Color(0xFF1A819A),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pregunta en negrita y con un tamaño de fuente más grande
                  Text(
                    faqs[index].question,
                    style: MyTextStyles.tittleButton,
                  ),
                  const SizedBox(
                      height: 8), // Espaciado entre pregunta y respuesta
                  // Respuesta con color gris y tamaño de fuente más pequeño
                  Text(
                    faqs[index].answer,
                    style: MyTextStyles.ButtonTextStyle,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class Faq {
  final String question;
  final String answer;

  Faq({required this.question, required this.answer});
}
