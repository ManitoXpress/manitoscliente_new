import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manitoscliente_new/ServicesResponse/dataprofile.dart';
import 'package:manitoscliente_new/ServicesResponse/resquest.dart';
import 'package:manitoscliente_new/Styles/stilo.dart';
import 'package:manitoscliente_new/metodos/serviceFetcher.dart';
import 'package:manitoscliente_new/metodos/ticketController.dart';
import 'package:manitoscliente_new/utils/timeLines.dart';

class ServiceListBuilder {
  static Widget buildOfferList(List<ServiceRequest> services,List<Offer> offers, double screenWidth,
      double screenHeight, String userId, final UserData userData) {
    final serviceDataFetcher = ServiceDataFetcher();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: ListView.builder(
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          // Busca el ServiceRequest correspondiente a esta oferta
          final service = services.firstWhere(
            (s) => s.id == offer.serviceId,
            orElse: () => throw Exception('Servicio no encontrado para oferta ${offer.id}'),
          );
          return GestureDetector(
            onTap: () async {
              try {
                final workerDetails =
                    await serviceDataFetcher.fetchWorkerDetails(offer.workerId);
                if (workerDetails == null) return;
                if (userData is UserData) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceFormWithTimeline(
                        serviceRequest: ServiceRequest(
                          id: offer.serviceId,
                          serviceDateTime: '',
                          devicesId: '',
                          description: '',
                          images: [],
                          location: {},
                          offeredPrice: offer.offeredPrice,
                          serviceType: ServiceType(
                              id: '',
                              name: '',
                              selectedDate: '',
                              selectedTime: ''),
                          workerId: offer.workerId,
                          isFavorite: false,
                          acceptedTerms: false,
                          expertises: offer.expertises,
                          status: Status(id: '', name: ''),
                          subcategoryName: offer.subcategoryName,
                          hasOffer: false,
                          offers: [],
                          workerDetails: workerDetails,
                          userId: '',
                        ),
                        initialStatus: offer.status.id,
                        onComplete: (status) {
                          print('Estado completado: $status');
                        },
                        onStatusChanged: (newStatus) {
                          print('Estado cambiado a: $newStatus');
                        },
                        userData: userData, // Solo lo pasa si es UserData
                        workerId: offer.workerId,
                        workerDetails: workerDetails,
                        offers: [],
                        images: [],
                      ),
                    ),
                  );
                }
              } catch (e) {
                print('Error al cargar los detalles del trabajador: $e');
              }
            },
            child: _buildOfferCard(service, offer, screenWidth, screenHeight),
          );
        },
      ),
    );
  }
  // ignore: non_constant_identifier_names
  static Widget in_progressList(List<ServiceRequest> services,List<Offer> offers, double screenWidth,
      double screenHeight, String userId, final UserData userData) {
    final serviceDataFetcher = ServiceDataFetcher();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: ListView.builder(
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          // Busca el ServiceRequest correspondiente a esta oferta
          final service = services.firstWhere(
            (s) => s.id == offer.serviceId,
            orElse: () => throw Exception('Servicio no encontrado para oferta ${offer.id}'),
          );
          return GestureDetector(
            onTap: () async {
              try {
                final workerDetails =
                    await serviceDataFetcher.fetchWorkerDetails(offer.workerId);
                if (workerDetails == null) return;
                if (userData is UserData) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceFormWithTimeline(
                        serviceRequest: ServiceRequest(
                          id: offer.serviceId,
                          serviceDateTime: '',
                          devicesId: '',
                          description: '',
                          images: [],
                          location: {},
                          offeredPrice: offer.offeredPrice,
                          serviceType: ServiceType(
                              id: '',
                              name: '',
                              selectedDate: '',
                              selectedTime: ''),
                          workerId: offer.workerId,
                          isFavorite: false,
                          acceptedTerms: false,
                          expertises: offer.expertises,
                          status: Status(id: '', name: ''),
                          subcategoryName: offer.subcategoryName,
                          hasOffer: false,
                          offers: [],
                          workerDetails: workerDetails,
                          userId: '',
                        ),
                        initialStatus: offer.status.id,
                        onComplete: (status) {
                          print('Estado completado: $status');
                        },
                        onStatusChanged: (newStatus) {
                          print('Estado cambiado a: $newStatus');
                        },
                        userData: userData, // Solo lo pasa si es UserData
                        workerId: offer.workerId,
                        workerDetails: workerDetails,
                        offers: [],
                        images: [],
                      ),
                    ),
                  );
                }
              } catch (e) {
                print('Error al cargar los detalles del trabajador: $e');
              }
            },
            child: _buildOfferCard(service, offer, screenWidth, screenHeight),
          );
        },
      ),
    );
  }

  static Widget buildServiceList(
      List<ServiceRequest> services,
      double screenWidth,
      double screenHeight,
      String userId,
      dynamic userData) {
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
                    builder: (context) => ServiceFormWithTimeline(
                      serviceRequest: ServiceRequest(
                        id: service.id,
                        serviceDateTime: '',
                        devicesId: '',
                        description: '',
                        images: [],
                        location: {},
                        offeredPrice: service.offeredPrice,
                        serviceType: ServiceType(
                            id: '',
                            name: '',
                            selectedDate: '',
                            selectedTime: ''),
                        workerId: service.workerId,
                        isFavorite: false,
                        acceptedTerms: false,
                        expertises: service.expertises,
                        status: Status(id: '', name: ''),
                        subcategoryName: service.subcategoryName,
                        hasOffer: false,
                        offers: [],
                        workerDetails: workerDetails,
                        userId: '',
                      ),
                      initialStatus: service.status.id,
                      onComplete: (status) {
                        print('Estado completado: $status');
                      },
                      onStatusChanged: (newStatus) {
                        print('Estado cambiado a: $newStatus');
                      },
                      userData: userData,
                      workerId: service.workerId,
                      workerDetails: workerDetails,
                      offers: [],
                      images: [],
                    ),
                  ),
                );
              } catch (e) {
                print('Error al cargar los detalles del trabajador: $e');
              }
            },
            child: _buildServiceCard(service, screenWidth, screenHeight),
          );
        },
      ),
    );
  }

  static Widget _buildOfferCard(ServiceRequest service,
      Offer offer, double screenWidth, double screenHeight) {
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
            screenHeight),
      ),
    );
  }

  static Widget _buildServiceCard(
      ServiceRequest service, double screenWidth, double screenHeight) {
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
            screenHeight),
      ),
    );
  }

  static Widget _buildCardContent(
      String category, String expertise, double price, double screenHeight) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 30),
                Text('Categoría:', style: MyTextStyles.drawerButtonTextStyle),
                Text(category, style: MyTextStyles.drawerButtonTextStyle5),
                SizedBox(height: screenHeight * 0.01),
                Text('Servicio:', style: MyTextStyles.drawerButtonTextStyle),
                Text(expertise, style: MyTextStyles.drawerButtonTextStyle5),
                SizedBox(height: screenHeight * 0.01),
                Text('Precio Ofertado: \$${price.toStringAsFixed(2)}',
                    style: MyTextStyles.drawerButtonTextStyle),
              ],
            ),
          ),
          SizedBox(width: 10),
          Align(
            alignment: Alignment.bottomLeft,
            child: Image.asset('assets/animations/manito.png',
                width: 64, height: 64),
          ),
        ],
      ),
    );
  }
}
