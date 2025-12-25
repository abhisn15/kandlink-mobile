import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/assignment_provider.dart';
import '../../../core/models/area.dart';
import '../../../ui/router/app_router.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class AreaSelectionScreen extends StatefulWidget {
  const AreaSelectionScreen({super.key});

  @override
  State<AreaSelectionScreen> createState() => _AreaSelectionScreenState();
}

class _AreaSelectionScreenState extends State<AreaSelectionScreen> {
  Area? _selectedArea;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAreas();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  Future<void> _loadAreas() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadAreas();
  }

  Future<void> _selectArea() async {
    if (_selectedArea == null) return;

    debugPrint(
        '🏙️ SELECTING_AREA: ${_selectedArea!.name} (${_selectedArea!.id})');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final assignmentProvider =
        Provider.of<AssignmentProvider>(context, listen: false);

    final success = await authProvider.updateProfile(areaId: _selectedArea!.id);

    if (success && mounted) {
      debugPrint('✅ AREA_SELECTED_SUCCESS: Loading PIC assignment...');

      // Load PIC assignment after area selection
      try {
        await assignmentProvider.loadCurrentPIC();
        debugPrint(
            '✅ PIC_ASSIGNMENT_LOADED: ${assignmentProvider.currentAssignment?.picId}');
      } catch (e) {
        debugPrint('❌ PIC_ASSIGNMENT_ERROR: $e');
      }

      // Navigate to home after successful area selection
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Area'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final areas = authProvider.areas;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Choose Your Area',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please select the area where you want to work as a candidate.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Search Field
                CustomTextField(
                  controller: _searchController,
                  labelText: 'Search Area',
                  hintText: 'Type to search areas...',
                  prefixIcon: Icons.search,
                ),
                const SizedBox(height: 16),

                // Areas List
                Expanded(
                  child: areas.isEmpty
                      ? const Center(
                          child: Text(
                            'No areas available',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _getFilteredAreas(areas).length,
                          itemBuilder: (context, index) {
                            final area = _getFilteredAreas(areas)[index];
                            final isSelected = _selectedArea?.id == area.id;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey,
                                ),
                                title: Text(
                                  area.name,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: null,
                                onTap: () {
                                  setState(() {
                                    _selectedArea = area;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 24),

                // Select Button
                CustomButton(
                  text: 'Continue',
                  onPressed: _selectedArea != null ? _selectArea : null,
                  isLoading: authProvider.isLoading,
                ),

                if (authProvider.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    authProvider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<Area> _getFilteredAreas(List<Area> areas) {
    final query = _searchQuery.toLowerCase();
    if (query.isEmpty) return areas;

    return areas
        .where((area) =>
            area.name.toLowerCase().contains(query) ||
            area.id.toLowerCase().contains(query))
        .toList();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}
