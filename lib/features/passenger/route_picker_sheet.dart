import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/route_data.dart';
import '../../data/route_loader.dart';

/// Modal bottom sheet allowing passenger to browse and select available routes
/// similar to Yandex Maps Transport ("Выбрать маршрут / транспорт").
class RoutePickerSheet extends ConsumerStatefulWidget {
  const RoutePickerSheet({super.key});

  static Future<RouteData?> show(BuildContext context) {
    return showModalBottomSheet<RouteData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RoutePickerSheet(),
    );
  }

  @override
  ConsumerState<RoutePickerSheet> createState() => _RoutePickerSheetState();
}

class _RoutePickerSheetState extends ConsumerState<RoutePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _parseRouteColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return const Color(0xFF006C50);
    try {
      final buffer = StringBuffer();
      if (hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF006C50);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routesAsync = ref.watch(routesFutureProvider);
    final currentRouteId = ref.watch(selectedRouteIdProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),

              // Title and close
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Маршруты Волгограда',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Search field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск маршрута или остановки...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _filterQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _filterQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _filterQuery = val.trim().toLowerCase();
                    });
                  },
                ),
              ),

              // Routes list
              Expanded(
                child: routesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Ошибка загрузки: $err')),
                  data: (routes) {
                    final filtered = routes.where((r) {
                      if (_filterQuery.isEmpty) return true;
                      if (r.id.toLowerCase().contains(_filterQuery)) return true;
                      if (r.name.toLowerCase().contains(_filterQuery)) return true;
                      return r.stops.any((s) => s.name.toLowerCase().contains(_filterQuery));
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                          'Маршруты не найдены',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final route = filtered[index];
                        final isSelected = route.id == currentRouteId;
                        final color = _parseRouteColor(route.color);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          leading: Container(
                            width: 52,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              route.id,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  route.name,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (route.type != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    route.type!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSecondaryContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (route.description != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  route.description!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                '${route.stops.length} остановок',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                              : const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () {
                            ref.read(selectedRouteIdProvider.notifier).selectRoute(route.id);
                            Navigator.of(context).pop(route);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}