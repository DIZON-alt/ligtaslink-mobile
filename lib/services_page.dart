import 'package:flutter/material.dart';

import 'services_api.dart';

const _ink = Color(0xFF18202B);
const _muted = Color(0xFF68717D);

class ServicesPage extends StatefulWidget {
  final ServicesApi api;
  final void Function(String serviceName) onRequest;

  const ServicesPage({
    super.key,
    required this.api,
    required this.onRequest,
  });

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  late Future<ServicesCatalog> _servicesFuture;
  String _query = '';
  String _category = 'All';

  @override
  void initState() {
    super.initState();
    _servicesFuture = widget.api.fetchServices();
  }

  void _refresh() {
    setState(() {
      _servicesFuture = widget.api.fetchServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ServicesCatalog>(
      future: _servicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorState(onRetry: _refresh);
        }
        final catalog = snapshot.data!;
        final categories = <String>{
          'All',
          ...catalog.services.map((service) => service.category),
        }.toList();
        final visibleServices = catalog.services.where((service) {
          final matchesCategory =
              _category == 'All' || service.category == _category;
          final searchText =
              '${service.name} ${service.description} ${service.category}'
                  .toLowerCase();
          return matchesCategory && searchText.contains(_query.toLowerCase());
        }).toList();

        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Services',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: _ink)),
                        SizedBox(height: 5),
                        Text('Find the right response team for your situation.',
                            style: TextStyle(color: _muted)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh services',
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (catalog.offlineMessage case final message?) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.cloud_off_outlined,
                          size: 18, color: _muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(color: _muted, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search services',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ChoiceChip(
                      label: Text(category),
                      selected: category == _category,
                      onSelected: (_) => setState(() => _category = category),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              if (visibleServices.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: Text('No services match your search.')),
                )
              else
                ...visibleServices.map(
                  (service) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ServiceCard(
                      service: service,
                      onRequest: () => widget.onRequest(service.name),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Text('Catalog updated ${catalog.updatedAt}',
                  style: const TextStyle(color: _muted, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceItem service;
  final VoidCallback onRequest;

  const _ServiceCard({required this.service, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: service.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(service.icon, color: service.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _ink)),
                      const SizedBox(height: 3),
                      Text(service.category.toUpperCase(),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: service.color,
                              letterSpacing: 0.6)),
                    ],
                  ),
                ),
                Icon(Icons.verified_outlined, color: service.color, size: 20),
              ],
            ),
            const SizedBox(height: 14),
            Text(service.description,
                style: const TextStyle(color: _muted, height: 1.35)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(
                    icon: Icons.schedule_outlined, text: service.availability),
                _InfoPill(
                    icon: Icons.timer_outlined, text: service.responseTime),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRequest,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Request this service'),
                style: FilledButton.styleFrom(backgroundColor: service.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: _muted),
      label: Text(text),
      labelStyle: const TextStyle(fontSize: 12, color: _muted),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: _muted),
            const SizedBox(height: 12),
            const Text('Services are unavailable',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Start the REST API and try again.',
                textAlign: TextAlign.center, style: TextStyle(color: _muted)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
