import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../Styles/stilo.dart';
import '../controller/serviceFetcher.dart';
import '../controller/ticketController.dart';
import '../provider/serviceDetails_providers.dart';
import '../request/ResponseGet.dart';
import '../request/ResponsePost.dart';
import '../request/dataprofile.dart';
import '../request/requestServiceType.dart';
import '../request/requestStatus.dart';
import '../request/resquest.dart';
import '../utils/timeLines.dart';
class ServiceListBuilder {
  /// Lista de ofertas ("Ofertas recibidas") usando Provider internamente.
  static Widget buildOfferList(
      List<ServiceRequest> services,
      List<Offer> offers,
      double screenWidth,
      double screenHeight,
      String userId,
      UserData userData,
      ApiService apiService,
      ) {
    final serviceDataFetcher = ServiceDataFetcher();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: ListView.builder(
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];

          // Buscamos el ServiceRequest en la lista local (si la tienes cargada).
          // Si no lo tienes, podrías omitir este paso y dejar que el Provider dentro de ServiceFormWithTimeline lo haga.
          final service = services.firstWhere(
                (s) => s.id == offer.serviceId,
            orElse: () => throw Exception(
              'Servicio no encontrado para oferta ${offer.id}',
            ),
          );

          return GestureDetector(
            onTap: () async {
              try {
                // Opcionalmente, aún puedes precargar detalles del trabajador.
                final workerDetails =
                await serviceDataFetcher.fetchWorkerDetails(offer.workerId);
                // Si necesitas chequear algo con workerDetails antes de navegar, lo haces aquí.
                // Pero el widget destino (ServiceFormWithTimeline) se encargará de refrescar en tiempo real.

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      // Envolvemos el nuevo screen en Provider
                      return ChangeNotifierProvider<ServiceDetailsProvider>(
                        create: (_) {
                          final prov = ServiceDetailsProvider(
                              serviceId: offer.serviceId,
                              workerId: offer.workerId,
                              apiService2: ApiService2()
                          );
                          // Inicia la suscripción y carga inicial
                          prov.init();
                          return prov;
                        },
                        child: ServiceFormWithTimeline(
                          // Ahora le pasamos los IDs; ya no necesitamos construir un ServiceRequest completo
                          serviceId: offer.serviceId,
                          initialStatus: offer.status.id,
                          onComplete: (status) {
                            null;
                          },
                          onStatusChanged: (newStatus) {
                            null;
                          },
                          userData: userData,
                          workerId: offer.workerId,
                          apiService: apiService,
                          userId: userId,
                        ),
                      );
                    },
                  ),
                );
              } catch (e) {
                // Mostrar error en consola o con SnackBar
                null;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No se pudo abrir los detalles del servicio.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: _buildOfferCard(service, offer, screenWidth, screenHeight),
          );
        },
      ),
    );
  }

  /// Lista de ofertas "En curso" (similar a buildOfferList)
  static Widget inProgressList(
      List<ServiceRequest> services,
      List<Offer> offers,
      double screenWidth,
      double screenHeight,
      String userId,
      UserData userData,
      ApiService apiService,
      ) {
    final serviceDataFetcher = ServiceDataFetcher();

    null;
    
    if (offers.isEmpty) {
      null;
      return const Center(
        child: Text(
          'No hay servicios en progreso',
          style: TextStyle(
            color: Color(0xFF1A819A),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: ListView.builder(
        shrinkWrap: true,
        // physics: const NeverScrollableScrollPhysics(),  // quítalo o cámbialo
        physics: const BouncingScrollPhysics(),          // por ejemplo
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          null;
          
          final service = services.firstWhere(
                (s) => s.id == offer.serviceId,
            orElse: () => throw Exception(
              'Servicio no encontrado para oferta ${offer.id}',
            ),
          );

          return GestureDetector(
            onTap: () async {
              try {
                final workerDetails = await serviceDataFetcher
                    .fetchWorkerDetails(offer.workerId);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return ChangeNotifierProvider<ServiceDetailsProvider>(
                        create: (_) {
                          final prov = ServiceDetailsProvider(
                            serviceId: offer.serviceId,
                            workerId: offer.workerId,
                            apiService2: ApiService2(),
                          );
                          prov.init();
                          return prov;
                        },
                        child: ServiceFormWithTimeline(
                          serviceId: offer.serviceId,
                          initialStatus: offer.status.id,
                          onComplete: (status) {
                            null;
                          },
                          onStatusChanged: (newStatus) {
                            null;
                          },
                          userData: userData,
                          workerId: offer.workerId,
                          apiService: apiService,
                          userId: userId,
                        ),
                      );
                    },
                  ),
                );
              } catch (e) {
                null;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No se pudo abrir los detalles del servicio.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: _buildOfferCard(service, offer, screenWidth, screenHeight),
          );
        },
      ),
    );
  }



  /// Lista de servicios disponibles sin ofertas
  static Widget buildServiceListAvailable(
      List<ServiceRequest> services,
      double screenWidth,
      double screenHeight,
      String userId,
      UserData userData,
      ApiService apiService,
      ) {
    final serviceDataFetcher = ServiceDataFetcher();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];

          return GestureDetector(
            onTap: () async {
              try {
                final workerDetails = await serviceDataFetcher
                    .fetchWorkerDetails(service.workerId);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return ChangeNotifierProvider<ServiceDetailsProvider>(
                        create: (_) {
                          final prov = ServiceDetailsProvider(
                              serviceId: service.id,
                              workerId: service.workerId,
                              apiService2: ApiService2()
                          );
                          prov.init();
                          return prov;
                        },
                        child: ServiceFormWithTimeline(
                          serviceId: service.id,
                          initialStatus: service.status.id,
                          onComplete: (status) {
                            null;
                          },
                          onStatusChanged: (newStatus) {
                            null;
                          },
                          userData: userData,
                          workerId: service.workerId,
                          apiService: apiService,
                          userId: userId,
                        ),
                      );
                    },
                  ),
                );
              } catch (e) {
                null;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No se pudo abrir los detalles del servicio.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: _buildServiceCard(service, screenWidth, screenHeight),
          );
        },
      ),
    );
  }

  /// Lista de servicios completados (usa la lista de offers para enlazar al servicio)
  static Widget buildServiceListComplete(
      List<ServiceRequest> services,
      List<Offer> offers,
      double screenWidth,
      double screenHeight,
      String userId,
      UserData userData,
      ApiService apiService,
      ) {
    final serviceDataFetcher = ServiceDataFetcher();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: ListView.builder(
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          final service = services.firstWhere(
                (s) => s.id == offer.serviceId,
            orElse: () => throw Exception(
              'Servicio no encontrado para oferta ${offer.id}',
            ),
          );

          return GestureDetector(
            onTap: () async {
              try {
                final workerDetails =
                await serviceDataFetcher.fetchWorkerDetails(offer.workerId);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return ChangeNotifierProvider<ServiceDetailsProvider>(
                        create: (_) {
                          final prov = ServiceDetailsProvider(
                              serviceId: offer.serviceId,
                              workerId: offer.workerId,
                              apiService2: ApiService2()
                          );
                          prov.init();
                          return prov;
                        },
                        child: ServiceFormWithTimeline(
                          serviceId: offer.serviceId,
                          initialStatus: offer.status.id,
                          onComplete: (status) {
                            null;
                          },
                          onStatusChanged: (newStatus) {
                            null;
                          },
                          userData: userData,
                          workerId: offer.workerId,
                          apiService: apiService,
                          userId: userId,
                        ),
                      );
                    },
                  ),
                );
              } catch (e) {
                null;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No se pudo abrir los detalles del servicio.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: _buildOfferCard(service, offer, screenWidth, screenHeight),
          );
        },
      ),
    );
  }

  /// Lista de servicios cancelados
  static Widget buildServiceListCancelled(
      List<ServiceRequest> services,
      double screenWidth,
      double screenHeight,
      String userId,
      UserData userData,
      ApiService apiService,
      ) {
    final serviceDataFetcher = ServiceDataFetcher();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          final offer = service.offers.isNotEmpty ? service.offers.first : null;

          return GestureDetector(
            onTap: () async {
              try {
                final workerDetails = await serviceDataFetcher
                    .fetchWorkerDetails(service.workerId);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return ChangeNotifierProvider<ServiceDetailsProvider>(
                        create: (_) {
                          final prov = ServiceDetailsProvider(
                              serviceId: service.id,
                              workerId: service.workerId,
                              apiService2: ApiService2()
                          );
                          prov.init();
                          return prov;
                        },
                        child: ServiceFormWithTimeline(
                          serviceId: service.id,
                          initialStatus: service.status.id,
                          onComplete: (status) =>
                              null,
                          onStatusChanged: (newStatus) =>
                              null,
                          userData: userData,
                          workerId: service.workerId,
                          apiService: apiService,
                          userId: userId,
                        ),
                      );
                    },
                  ),
                );
              } catch (e) {
                null;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No se pudo abrir los detalles del servicio.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: _buildServiceCard(service, screenWidth, screenHeight),
          );
        },
      ),
    );
  }

  /// Lista genérica de servicios/ofertas
  static Widget buildServiceList(
      List<ServiceRequest> services,
      List<Offer> offers,
      double screenWidth,
      double screenHeight,
      String userId,
      UserData userData,
      ApiService apiService,
      ) {
    final serviceDataFetcher = ServiceDataFetcher();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: ListView.builder(
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          final service = services.firstWhere(
                (s) => s.id == offer.serviceId,
            orElse: () => throw Exception(
              'Servicio no encontrado para oferta ${offer.id}',
            ),
          );

          return GestureDetector(
            onTap: () async {
              try {
                final workerDetails = await serviceDataFetcher
                    .fetchWorkerDetails(service.workerId);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return ChangeNotifierProvider<ServiceDetailsProvider>(
                        create: (_) {
                          final prov = ServiceDetailsProvider(
                              serviceId: service.id,
                              workerId: service.workerId,
                              apiService2: ApiService2()
                          );
                          prov.init();
                          return prov;
                        },
                        child: ServiceFormWithTimeline(
                          serviceId: service.id,
                          initialStatus: service.status.id,
                          onComplete: (status) {
                            null;
                          },
                          onStatusChanged: (newStatus) {
                            null;
                          },
                          userData: userData,
                          workerId: service.workerId,
                          apiService: apiService,
                          userId: userId,
                        ),
                      );
                    },
                  ),
                );
              } catch (e) {
                null;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No se pudo abrir los detalles del servicio.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: _buildOfferCard(service, offer, screenWidth, screenHeight),
          );
        },
      ),
    );
  }

  /// Misma tarjeta para ofertas que antes
  static Widget _buildOfferCard(
      ServiceRequest service,
      Offer offer,
      double screenWidth,
      double screenHeight,
      ) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      width: screenWidth,
      height: screenHeight * 0.24,
      child: CustomPaint(
        size: Size(screenWidth, screenHeight * 0.35),
        painter: CustomTicketShapePainter(status: service.status),
        child: _buildCardContent(
          service.subcategoryName,
          service.expertises.map((e) => e.name).join(', '),
          offer.offeredPrice,
          screenHeight,
        ),
      ),
    );
  }

  /// Misma tarjeta para servicios que antes
  static Widget _buildServiceCard(
      ServiceRequest service,
      double screenWidth,
      double screenHeight,
      ) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      width: screenWidth,
      height: screenHeight * 0.24,
      child: CustomPaint(
        size: Size(screenWidth, screenHeight * 0.35),
        painter: CustomTicketShapePainter(status: service.status),
        child: _buildCardContent(
          service.subcategoryName,
          service.expertises.map((e) => e.name).join(', '),
          service.offeredPrice,
          screenHeight,
        ),
      ),
    );
  }

  static Widget _buildCardContent(
      String category,
      String expertise,
      double price,
      double screenHeight,
      ) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    Text(
                      'Categoría:',
                      style: MyTextStyles.drawerButtonTextStyle7,
                    ),
                    Text(category, style: MyTextStyles.serviceTextStyle),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      'Servicio:',
                      style: MyTextStyles.drawerButtonTextStyle7,
                    ),
                    Text(expertise, style: MyTextStyles.serviceTextStyle),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      'Precio Ofertado: \Bs.${price.toStringAsFixed(2)}',
                      style: MyTextStyles.drawerButtonTextStyle7,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Align(
                alignment: Alignment.bottomLeft,
                child: Image.asset(
                  'assets/animations/manito.png',
                  width: 64,
                  height: 64,
                ),
              ),
            ],
            ),
        );
    }
}