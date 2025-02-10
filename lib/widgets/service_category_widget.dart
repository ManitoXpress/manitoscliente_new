import 'package:flutter/material.dart';
import 'package:manitoscliente_new/request/ResponseGet.dart';
import '../Styles/stilo.dart';

import 'package:flutter/material.dart';

class ServiceCategoryWidget extends StatelessWidget {
  final ServiceResponse service;
  final VoidCallback onTap;

  ServiceCategoryWidget({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width - 100,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF1A819A).withOpacity(0.5),
                  spreadRadius: 4,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: Image.network(
                service.image,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            service.name,
            style: MyTextStyles.drawerButtonTextStyle2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
