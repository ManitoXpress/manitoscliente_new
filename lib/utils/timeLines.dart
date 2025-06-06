// lib/widgets/service_form_with_timeline.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'package:flutter/material.dart';

import 'package:manitoscliente_new/Styles/stilo.dart';
import 'package:manitoscliente_new/constants/service_constants.dart';
import 'package:manitoscliente_new/models/service_requestModels.dart';
import 'package:manitoscliente_new/models/worker_detailsModels.dart';
import 'package:manitoscliente_new/provider/serviceDetails_providers.dart';
import 'package:manitoscliente_new/request/ResponseGet.dart';
import 'package:manitoscliente_new/request/ResponsePost.dart';
import 'package:manitoscliente_new/request/dataprofile.dart';

import 'package:manitoscliente_new/widgets/commentWdiget.dart';
import 'package:manitoscliente_new/widgets/imagePreview.dart';

import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiceFormWithTimeline extends StatelessWidget {
  final String serviceId;
  final String initialStatus;
  final ValueChanged<String> onComplete;
  final Function(String) onStatusChanged;
  final UserData userData;
  final String workerId;
  final ApiService apiService;
  final String userId;

  const ServiceFormWithTimeline({
    Key? key,
    required this.serviceId,
    required this.initialStatus,
    required this.onComplete,
    required this.onStatusChanged,
    required this.userData,
    required this.workerId,
    required this.apiService,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ServiceDetailsProvider>(
      create: (_) {
        final prov = ServiceDetailsProvider(
          serviceId: serviceId,
          workerId: workerId,
      
          apiService2: ApiService2()
        );
        prov.init();
        return prov;
      },
      child: Consumer<ServiceDetailsProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.errorMessage != null) {
            return Scaffold(
              appBar: AppBar(
                iconTheme: const IconThemeData(color: Colors.white),
                title: const Text(
                  'Detalles del Servicio',
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppColors.primary,
              ),
              body: Center(
                child: Text(
                  prov.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final serviceData = prov.service!;
          final workerDet = prov.workerDetails;
          final comentarios = prov.comments;
          final hasOffer = prov.hasOffer;

          // Obtener precio ofertado del array rawOffers (si existe)
          double? _workerOfferedPrice;
          if (serviceData.rawOffers.isNotEmpty) {
            final anyOffer = serviceData.rawOffers.firstWhere(
              (o) => o['workerId'] == workerId,
              orElse: () => {},
            );
            if (anyOffer.isNotEmpty) {
              _workerOfferedPrice = (anyOffer['offeredPrice'] as num?)?.toDouble();
            }
          }

          return Scaffold(
            appBar: AppBar(
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text(
                'Detalles del Servicio',
                style: MyTextStyles.buttonTextStyle,
              ),
              backgroundColor: const Color(0xFF1A819A),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.secondary,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Estado
                      Text(
                        'Estado: ${statusNames[serviceData.status] ?? 'Desconocido'}',
                        style: MyTextStyles.inputTextStyle6,
                      ),
                      const SizedBox(height: 8),
                      // Fecha y Hora
                      Text(
                        'Fecha: ${serviceData.date}',
                        style: MyTextStyles.inputTextStyle1),
                      const SizedBox(height: 4),
                      Text(
                        'Hora: ${serviceData.time}',
                        style: MyTextStyles.inputTextStyle1),
                      const SizedBox(height: 16),
                      // Descripción
                      _buildRichText(
                        'Descripción:',
                        serviceData.description,
                      ),
                      const SizedBox(height: 16),

                      // Carrusel de imágenes
                      if (serviceData.images.isNotEmpty)
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 200.0,
                            enlargeCenterPage: true,
                            autoPlay: true,
                            aspectRatio: 16 / 9,
                            autoPlayCurve: Curves.fastOutSlowIn,
                            enableInfiniteScroll: true,
                            autoPlayAnimationDuration: const Duration(milliseconds: 500),
                            viewportFraction: 0.5,
                          ),
                          items: serviceData.images.map((url) {
                            return Builder(
                              builder: (BuildContext context) {
                                return GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ImageViewer(imageUrl: url),
                                    ),
                                  ),
                                  child: Hero(
                                    tag: url,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12.0),
                                      child: CachedNetworkImage(
                                        imageUrl: url,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) =>
                                            const Center(child: CircularProgressIndicator()),
                                        errorWidget: (_, __, ___) => const Icon(Icons.error),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),

                      // Expertises
                      if (serviceData.expertises.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: serviceData.expertises.map((e) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text(
                                'Tipo de servicio: ${e.name}',
                                style: MyTextStyles.inputTextStyle6,)
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),

                      // Detalles del trabajador
                      if (workerDet != null || serviceData.status == ServiceStatus.inProgress)
                        ExpansionTile(
                          title: Text(
                            'Ver detalles del trabajador',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Karla',
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          children: [
                            _buildWorkerDetails(workerDet!, serviceData),
                          ],
                        ),

                      const SizedBox(height: 16),

                      // Botones de acción
                      _buildActionButtons(
                        context,
                        prov,
                        serviceData,
                        workerId,
                        _workerOfferedPrice,
                        comentarios.length,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRichText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text.rich(
        TextSpan(
          text: '$label ',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Karla',
            color: AppColors.secondary,
          ),
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Karla',
                color: Colors.black87,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildWorkerDetails(WorkerDetailsModel worker, ServiceRequestModel serviceData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trabajador',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Karla',
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del trabajador
              CachedNetworkImage(
                imageUrl: worker.imagePath,
                height: 150.0,
                width: 150.0,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
              const SizedBox(width: 16.0),
              // Documento de identidad
              CachedNetworkImage(
                imageUrl: worker.idDocumentImagePath,
                height: 150.0,
                width: 150.0,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          _buildRichText('Nombre:', worker.displayName),
          const SizedBox(height: 8.0),
          _buildRichText('Correo:', worker.email),
          const SizedBox(height: 8.0),
          _buildRichText(
            'Nivel de Experiencia:',
            worker.expLevel?.toString() ?? 'No disponible',
          ),
          const SizedBox(height: 8.0),
          _buildRichText(
            'Especialidad:',
            worker.expertises.isNotEmpty
                ? worker.expertises.map((e) => e.name).join(', ')
                : 'No disponible',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ServiceDetailsProvider prov,
    ServiceRequestModel serviceData,
    String selectedWorkerId,
    double? offeredPrice,
    int commentCount,
  ) {
    final hasOffer = prov.hasOffer;
    final status = serviceData.status;

    // 1) Si hay oferta pendiente
    if (hasOffer) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await prov.acceptProposal(selectedWorkerId);

                  if (prov.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(prov.errorMessage!),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    onStatusChanged(ServiceStatus.inProgress);
                  }
                },
                icon: Icon(Icons.architecture, color: AppColors.secondary),
                label: Text(
                  "Aceptar Propuesta",
                  style: TextStyle(
                    fontFamily: 'Karla',
                    color: AppColors.secondary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    side: BorderSide(color: AppColors.secondary),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await prov.cancelService();
                  if (prov.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(prov.errorMessage!),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.dangerous, color: Colors.white),
                label: const Text(
                  "Cancelar Trabajo",
                  style: TextStyle(
                    fontFamily: 'Karla',
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _showCommentsModal(context, prov),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              padding: EdgeInsets.symmetric(
                vertical: 25,
                horizontal: MediaQuery.of(context).size.width * 0.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.comment, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Comentarios ($commentCount)',
                  style: const TextStyle(
                    fontFamily: 'Karla',
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 2) Si está en progreso
    else if (status == ServiceStatus.inProgress) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: () async {
              await prov.cancelService();
              if (prov.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(prov.errorMessage!),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.dangerous, color: Colors.white),
            label: const Text(
              "Cancelar Trabajo",
              style: TextStyle(
                fontFamily: 'Karla',
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final url = await prov.getWhatsAppUrl();
              if (url != null) {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo abrir WhatsApp.'),
                    ),
                  );
                }
              } else if (prov.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(prov.errorMessage!),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.chat, color: Colors.white),
            label: const Text(
              "WhatsApp",
              style: TextStyle(
                fontFamily: 'Karla',
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.whatsappGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ],
      );
    }

    // 3) Disponible sin ofertas
    else if (status == ServiceStatus.available) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await prov.cancelService();
                  if (prov.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(prov.errorMessage!),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.dangerous, color: Colors.white),
                label: const Text(
                  "Cancelar Trabajo",
                  style: TextStyle(
                    fontFamily: 'Karla',
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _showCommentsModal(context, prov),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              padding: EdgeInsets.symmetric(
                vertical: 25,
                horizontal: MediaQuery.of(context).size.width * 0.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.comment, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Comentarios ($commentCount)',
                  style: const TextStyle(
                    fontFamily: 'Karla',
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _showCommentsModal(BuildContext context, ServiceDetailsProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return CommentsBottomSheet(provider: provider);
      },
    );
  }
}


/// Simple full‐screen viewer de imágenes.
