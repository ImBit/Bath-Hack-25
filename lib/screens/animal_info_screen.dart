import 'package:flutter/material.dart';

class AnimalInfoScreen extends StatelessWidget {
  const AnimalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final animalName = ModalRoute.of(context)?.settings.arguments as String? ?? 'Unknown Animal';

    return Scaffold(
      appBar: AppBar(
        title: Text(animalName),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://via.placeholder.com/300x200?text=$animalName',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'About',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This section would contain information about the specific animal species, '
                  'including its habitat, conservation status, and interesting facts.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              'Conservation Status',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Information about the conservation status would appear here, '
                  'including population trends and threats to the species.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}