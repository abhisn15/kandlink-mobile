import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/assignment_provider.dart';
import '../../widgets/common/custom_button.dart';

class AreaSelectionScreen extends StatefulWidget {
  const AreaSelectionScreen({super.key});

  @override
  State<AreaSelectionScreen> createState() => _AreaSelectionScreenState();
}

class _AreaSelectionScreenState extends State<AreaSelectionScreen> {
  String? _selectedAreaId;

  @override
  void initState() {
    super.initState();
    // Load areas when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).loadAreas();
    });
  }

  Future<void> _handleAreaSelection() async {
    if (_selectedAreaId == null) return;

    final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);

    final success = await assignmentProvider.assignPIC(_selectedAreaId!);

    if (success && mounted) {
      // Show success message and navigate to PIC info screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PIC berhasil diassign! Anda akan dihubungkan dengan PIC di area ini.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Navigate back to home or to PIC details screen
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final assignmentProvider = Provider.of<AssignmentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Area'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your area/location',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'This will help us connect you with the right PIC in your area.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 24),

            if (authProvider.isLoading || assignmentProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (authProvider.error != null || assignmentProvider.error != null)
              Center(
                child: Column(
                  children: [
                    Text(
                      'Error: ${authProvider.error ?? assignmentProvider.error}',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Retry',
                      onPressed: () => authProvider.loadAreas(),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: authProvider.areas.length,
                  itemBuilder: (context, index) {
                    final area = authProvider.areas[index];
                    final isSelected = _selectedAreaId == area.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: RadioListTile<String>(
                        title: Text(
                          area.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: area.description != null
                            ? Text(area.description!)
                            : null,
                        value: area.id,
                        groupValue: _selectedAreaId,
                        onChanged: (value) {
                          setState(() {
                            _selectedAreaId = value;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 24),

            CustomButton(
              text: 'Continue & Assign PIC',
              onPressed: _selectedAreaId != null && !authProvider.isLoading && !assignmentProvider.isLoading
                  ? _handleAreaSelection
                  : null,
              isLoading: assignmentProvider.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
