import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:manitoscliente_new/controller/home_Provider.dart';
import 'package:manitoscliente_new/provider/dataProvider.dart';

import '../request/resquest.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../Styles/stilo.dart';

import '../utils/status.dart';
import 'Service_DetailsScreen.dart';
// home_services_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeServicesScreen extends StatelessWidget {
  final String parentCategoryId;
  const HomeServicesScreen({Key? key, required this.parentCategoryId,})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
      HomeServicesProvider()..loadServices(parentId: parentCategoryId),
      child: const _HomeServicesView(),
    );
  }
}

class _HomeServicesView extends StatelessWidget {
  const _HomeServicesView();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HomeServicesProvider>();

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: true,
        title: prov.isSearching
            ? Container(
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            onChanged: prov.filter,
            decoration: InputDecoration(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 15),
              hintText: 'Buscar servicios...',
              border: InputBorder.none,
              suffixIcon:
              prov.displayedServices.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear,
                    color: Color(0xFF1A819A)),
                onPressed: prov.clearFilter,
              )
                  : null,
            ),
          ),
        )
            : const Text(
          'Servicios Profesionales',
          style: MyTextStyles.buttonTextStyle,
        ),
        actions: [
          IconButton(
            icon: Icon(
              prov.isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: prov.toggleSearchMode,
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: prov.clearSelection,
        child: Container(
          color: const Color(0xFF6AB8D6),
          child: Column(
            children: const [
              SizedBox(height: 20),
              Expanded(child: _ServiceGrid()),
              SizedBox(height: 10),
              _DetailsPanel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HomeServicesProvider>();
    if (prov.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.errorMessage != null) {
      return Center(child: Text('Error: ${prov.errorMessage}'));
    }
    if (prov.displayedServices.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron servicios',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 20, mainAxisSpacing: 20),
      itemCount: prov.displayedServices.length,
      itemBuilder: (_, i) {
        final svc = prov.displayedServices[i];
        return GestureDetector(
          onTap: () => prov.selectIndex(i),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A819A).withOpacity(0.15),
                  spreadRadius: 0.5,
                  blurRadius: 2,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl: svc.image,
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                  const CircularProgressIndicator(),
                  errorWidget: (_, __, ___) => const Icon(Icons.error),
                ),
                const SizedBox(height: 8),
                Text(
                  svc.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MyTextStyles.drawerButtonTextStyle1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HomeServicesProvider>();
    if (!prov.hasSelection) return const SizedBox.shrink();
    final svc = prov.selectedService!;
    // 2) Obtenemos el UserData desde el provider (o la fuente que uses)
    //    Este provider debe haber sido registrado en un nivel superior (por ejemplo, en main.dart).
    final userData = context.read<UserDataProvider>().userData;
    final nowIso = DateTime.now().toUtc().toIso8601String();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 4,
      margin: const EdgeInsets.all(10),
      child: SizedBox(
        // Ajusta la altura según convenga
        height: MediaQuery.of(context).size.height * 0.55,
        child: ListView(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              svc.name,
              style: MyTextStyles.titleTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              svc.description,
              style: MyTextStyles.formServiceTextStyle,
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.arrow_drop_down, color: Color(0xFF20819A)),
                SizedBox(width: 8),
                Text(
                  'Deslice hacia abajo para más:',
                  style: TextStyle(
                    color: Color(0xFF20819A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...svc.serviceTypes.map((type) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  onPressed: () {
                    final status = StatusUtils.getStatusById('');
                    final req = ServiceRequest(
                      serviceDateTime: nowIso,
                      description: '',
                      images: [],
                      location: {'lat': 0, 'lng': 0},
                      offeredPrice: 0,
                      serviceType: type,
                      userId: userData.userId,
                      workerId: '',
                      isFavorite: false,
                      selectedDate: nowIso,
                      selectedTime: type.selectedTime ?? '',
                      acceptedTerms: true,
                      id: '',
                      status: status,
                      expertises: [],
                      devicesId: '',
                      hasOffer: false,
                      offers: [],
                      subcategoryName: svc.name, createdAt: DateTime.now(),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceFormPage(
                          serviceRequest: req,
                          acceptTerms: true,
                          selectedDate: DateTime.now(),
                          token: '',
                          selectedServiceTitle: type.name,
                          selectedTime: '',
                          serviceRequests: [],
                          categoryId: svc.parentId!,
                          expertiseId: svc.id,
                          expertiseName: svc.name,
                          userData: userData, // ← importante: lo pasamos aquí
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20819A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(
                    type.name,
                    style: MyTextStyles.buttonTextStyle,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}