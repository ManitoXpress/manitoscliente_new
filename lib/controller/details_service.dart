import 'package:flutter/material.dart';
import 'package:manitoscliente_new/Styles/stilo.dart';
import 'package:manitoscliente_new/categorias/Service_DetailsScreen.dart';
import 'package:manitoscliente_new/controller/service_provider.dart';
import 'package:manitoscliente_new/request/resquest.dart';
import 'package:manitoscliente_new/utils/status.dart';
import 'package:provider/provider.dart';

class _DetailsPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProfessionalServicesProvider>(
      builder: (_, prov, __) {
        if (!prov.hasSelection) return const SizedBox.shrink();
        final svc = prov.selectedService!;
        final nowIso = DateTime.now().toUtc().toIso8601String();

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          margin: const EdgeInsets.all(10),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: svc.serviceTypes.map((type) {
                      return SizedBox(
                        width: double.infinity,
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
                              userId: '',
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
                            minimumSize: const Size(0, 50),
                            maximumSize: const Size(double.infinity, 50),
                          ),
                          child: Text(
                            type.name,
                            style: MyTextStyles.buttonTextStyle,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
