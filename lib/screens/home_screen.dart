import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/rounded_button.dart';
import 'result_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickAndOpenResult(
    BuildContext context,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ResultScreen(imagePath: file.path)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SvgPicture.asset('assets/logo.svg', width: 44, height: 44),
                  const SizedBox(width: 12),
                  const Text(
                    'EcoSort AI',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/history'),
                    icon: const Icon(Icons.history_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Classify Your Trash',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tip: Rinse containers before recycling to avoid contamination.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RoundedButton(
                        label: 'Take Photo',
                        icon: Icons.camera_alt_outlined,
                        onTap: () => Navigator.of(context).pushNamed('/camera'),
                        large: true,
                      ),
                      const SizedBox(height: 14),
                      TextButton.icon(
                        onPressed: () =>
                            _pickAndOpenResult(context, ImageSource.gallery),
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Upload from Gallery'),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withOpacity(0.06),
                              Colors.white,
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.recycling, color: Colors.green),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Recycling Stats',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'You saved 2.4kg CO₂ • 120 points',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_outlined),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) {
          if (i == 1) Navigator.of(context).pushNamed('/history');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_filled), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'History'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
      ),
    );
  }
}
