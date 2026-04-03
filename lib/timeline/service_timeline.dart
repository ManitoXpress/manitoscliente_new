import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../Styles/stilo.dart';
import '../constant/serviceConstants.dart';
import '../models/service_requestModels.dart';
import '../models/worker_detailsModels.dart';
import '../provider/serviceDetails_providers.dart';
import '../request/requestWoker.dart';
import '../request/resquest.dart';
import '../request/dataprofile.dart';
import '../request/ResponsePost.dart';
import '../request/ResponseGet.dart';
import '../widgets/commentButtonWidget.dart';
import '../widgets/completeDialog.dart';
import '../widgets/imagePreview.dart';

import 'service_info_section.dart';
import 'payment_report_section.dart';
import 'worker_details_section.dart';
import 'action_buttons_section.dart';
import 'timeline_helpers.dart';

class ServiceFormWithTimeline extends StatefulWidget {
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
  State<ServiceFormWithTimeline> createState() => _ServiceFormWithTimelineState();
}

class _ServiceFormWithTimelineState extends State<ServiceFormWithTimeline> with SingleTickerProviderStateMixin, RestorationMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = true;
  late AnimationController _animationController;
  late Animation<Offset> _bounceAnimation;
  final RestorableDouble _scrollOffset = RestorableDouble(0.0);

  @override
  String? get restorationId => 'service_timeline_screen';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _scrollController.addListener(_saveScrollOffset);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _bounceAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, 0.25),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.removeListener(_saveScrollOffset);
    _scrollController.dispose();
    _animationController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_scrollOffset, 'timeline_scroll_offset');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollOffset.value > 0.0) {
        _scrollController.jumpTo(_scrollOffset.value);
      }
    });
  }

  void _saveScrollOffset() {
    if (_scrollController.hasClients) {
      _scrollOffset.value = _scrollController.offset;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels > 10) {
      if (_showScrollIndicator) {
        setState(() {
          _showScrollIndicator = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ServiceDetailsProvider>(
      create: (_) {
        final prov = ServiceDetailsProvider(
            serviceId: widget.serviceId,
            workerId: widget.workerId,
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
                    fontFamily: 'Xpress Heavy',
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

          return Scaffold(
            appBar: AppBar(
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text(
                'Detalles del Servicio',
                style: MyTextStyles.buttonTextStyle,
              ),
              backgroundColor: const Color(0xFF1A819A),
            ),
            body: FutureBuilder<double?>(
              future: TimelineHelpers.getOfferedPrice(serviceData, widget.workerId),
              builder: (context, snapshot) {
                double? workerOfferedPrice = snapshot.data;
                
                return Stack(
                  children: [
                    SingleChildScrollView(
                      controller: _scrollController,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
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
                              // Sección de información del servicio
                              ServiceInfoSection(serviceData: serviceData),
                              
                              const SizedBox(height: 16),

                              // Informe de Pago
                              if (workerOfferedPrice != null && workerOfferedPrice > 0)
                                PaymentReportSection.buildPaymentReport(workerOfferedPrice)
                              else if (workerDet != null || 
                                       serviceData.status == ServiceStatus.inProgress || 
                                       serviceData.status == ServiceStatus.completed)
                                PaymentReportSection.buildPaymentReportPlaceholder(),

                              const SizedBox(height: 16),

                              // Detalles del trabajador
                              if (workerDet != null || serviceData.status == ServiceStatus.inProgress)
                                WorkerDetailsSection(
                                  worker: workerDet!,
                                  serviceData: serviceData,
                                ),

                              const SizedBox(height: 16),

                              // Botones de acción
                              ActionButtonsSection(
                                context: context,
                                prov: prov,
                                serviceData: serviceData,
                                workerId: widget.workerId,
                                offeredPrice: workerOfferedPrice,
                                commentCount: comentarios.length,
                                onStatusChanged: widget.onStatusChanged,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Flecha animada de rebote
                    if (_showScrollIndicator)
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: AnimatedOpacity(
                          opacity: _showScrollIndicator ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: IgnorePointer(
                            child: Center(
                              child: AnimatedBuilder(
                                animation: _bounceAnimation,
                                builder: (context, child) {
                                  return SlideTransition(
                                    position: _bounceAnimation,
                                    child: child,
                                  );
                                },
                                child: Icon(
                                  Icons.arrow_downward,
                                  color: Colors.grey[600],
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
} 