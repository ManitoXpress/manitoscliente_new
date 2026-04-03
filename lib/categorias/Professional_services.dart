import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:searchbar_animation/searchbar_animation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../Styles/stilo.dart';
import '../controller/auth_utils.dart';
import '../controller/home_screen_functions.dart';
import '../provider/dataProvider.dart';
import '../provider/service_provider.dart';
import '../request/ResponseGet.dart';
import '../request/requestExpertise.dart';
import '../request/requestServiceType.dart';
import '../request/resquest.dart';
import '../utils/status.dart';
import 'Service_DetailsScreen.dart';

class ProfessionalServicesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfessionalServicesProvider()..loadServices(),
      child: const _ProfessionalServicesView(),
    );
  }
}

class _ProfessionalServicesView extends StatelessWidget {
  const _ProfessionalServicesView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfessionalServicesProvider>();

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: true,
        title: provider.isSearching
            ? Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  onChanged: provider.filter,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    hintText: 'Buscar servicios...',
                    border: InputBorder.none,
                    suffixIcon: provider.displayedServices.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Color(0xFF1A819A)),
                            onPressed: provider.clearFilter,
                          )
                        : null,
                  ),
                ),
              )
            : const Text(
                'Servicios de hogar',
                style: MyTextStyles.buttonTextStyle,
              ),
        actions: [
          IconButton(
            icon: Icon(
              provider.isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: provider.toggleSearchMode,
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque, // << permite detectar taps fuera
        onTap: () =>
            context.read<ProfessionalServicesProvider>().clearSelection(),
        child: Container(
          color: const Color(0xFF6AB8D6),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Expanded(child: _ServiceGrid()),
              const SizedBox(height: 10),
              _DetailsPanel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProfessionalServicesProvider>(
      builder: (ctx, prov, _) {
        return TextField(
          decoration: InputDecoration(
            hintText: 'Buscar servicios...',
            border: InputBorder.none,
            suffixIcon: prov.displayedServices.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: prov.clearFilter,
                  )
                : null,
          ),
          onChanged: prov.filter,
        );
      },
    );
  }
}

class _ServiceGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProfessionalServicesProvider>(
      builder: (ctx, prov, _) {
        if (prov.isLoading)
          return const Center(child: CircularProgressIndicator());
        if (prov.errorMessage != null)
          return Center(child: Text('Error: \${prov.errorMessage}'));
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
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: prov.displayedServices.length,
          itemBuilder: (_, i) {
            final svc = prov.displayedServices[i];
            return GestureDetector(
              onTap: () {
                // Verificar si el servicio está bloqueado
                if (prov.isServiceBlocked(svc)) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF20819A)),
                            SizedBox(height: 8),
                            Text(
                              'Servicio no disponible',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        content: Text(
                          'Este servicio estará disponible muy pronto. ¡Gracias por tu paciencia!',
                          style: TextStyle(fontSize: 16),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Entendido',
                              style: TextStyle(
                                color: Color(0xFF20819A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      );
                    },
                  );
                } else {
                  prov.selectIndex(i);
                }
              },
              child: SizedBox(
                height: 170,
                width: double.infinity,
                child: Stack(
                  children: [
                    Container(
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Center(
                              child: CachedNetworkImage(
                                imageUrl: svc.image,
                                height: 70,
                                width: 70,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (_, __, ___) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            svc.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: prov.isServiceBlocked(svc)
                                ? MyTextStyles.drawerButtonTextStyle1.copyWith(
                                    color: Colors.white.withOpacity(0.5))
                                : MyTextStyles.drawerButtonTextStyle1,
                          ),
                        ],
                      ),
                    ),
                    // Overlay para servicios bloqueados
                    if (prov.isServiceBlocked(svc))
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900]?.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final maxHeight = constraints.maxHeight;
                                final iconSize = maxHeight * 0.18 > 40
                                    ? 40.0
                                    : maxHeight * 0.18;
                                final profIconSize = maxHeight * 0.16 > 38
                                    ? 38.0
                                    : maxHeight * 0.16;
                                return SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: 0,
                                      maxHeight: maxHeight,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 1.0, end: 1.15),
                                          duration: const Duration(seconds: 1),
                                          curve: Curves.easeInOut,
                                          builder: (context, scale, child) {
                                            return Transform.scale(
                                              scale: scale,
                                              child: Icon(Icons.lock_outline,
                                                  color: Colors.white,
                                                  size: iconSize),
                                            );
                                          },
                                          onEnd: () {},
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Próximamente',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: maxHeight * 0.09 > 17
                                                ? 17
                                                : maxHeight * 0.09,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          svc.name,
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.95),
                                            fontSize: maxHeight * 0.05 > 11
                                                ? 11
                                                : maxHeight * 0.05,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel();

  @override
  Widget build(BuildContext context) {
    // 1) Obtenemos el provider de servicios profesionales
    final prov = context.watch<ProfessionalServicesProvider>();
    if (!prov.hasSelection) return const SizedBox.shrink();
    final svc = prov.selectedService!;

    // 2) Obtenemos el UserData desde el provider (o la fuente que uses)
    //    Este provider debe haber sido registrado en un nivel superior (por ejemplo, en main.dart).
    final userData = context.read<UserDataProvider>().userData;

    // 3) Calculamos la fecha/hora actual en ISO
    final nowIso = DateTime.now().toUtc().toIso8601String();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 4,
      margin: const EdgeInsets.all(10),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.35,
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

            // 4) Por cada tipo de servicio, mostramos un botón que abre ServiceFormPage
            ...svc.serviceTypes.map((type) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  onPressed: () async {
                    // 4.a) Creamos un ServiceRequest base para enviar al formulario
                    final status = StatusUtils.getStatusById('');
                    final req = ServiceRequest(
                      serviceDateTime: nowIso,
                      description: '',
                      images: [],
                      location: {'lat': 0, 'lng': 0},
                      offeredPrice: 0,
                      serviceType: type,
                      userId: userData.userId, // ← si quieres prellenar userId
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
                      subcategoryName: svc.name,
                      createdAt: DateTime.now(),
                    );

                    // 4.b) Navegamos a ServiceFormPage, pasándole userData
                    String? token = await AuthUtils.getToken();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceFormPage(
                          serviceRequest: req,
                          acceptTerms: true,
                          serviceRequests: [], // ← lista si la necesitas
                          selectedDate: DateTime.now(),
                          selectedTime: type.selectedTime ?? '',
                          selectedServiceTitle: type.name,
                          token: token ?? '', // ← ahora pasamos el token real
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
