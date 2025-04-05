import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';
import '../models/animal_photo.dart';
import '../widgets/animal_photo_card.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<AnimalPhoto> photos = [
      AnimalPhoto(
        id: '1',
        name: 'Lion',
        imageUrl: 'https://via.placeholder.com/150?text=Lion',
        date: DateTime.now().subtract(const Duration(days: 2)),
        location: 'PLACEHOLDER LOCATION',
      ),
      AnimalPhoto(
        id: '2',
        name: 'Elephant',
        imageUrl: 'https://via.placeholder.com/150?text=Elephant',
        date: DateTime.now().subtract(const Duration(days: 5)),
        location: 'PLACEHOLDER LOCATION',
      ),
      AnimalPhoto(
        id: '3',
        name: 'Giraffe',
        imageUrl: 'https://via.placeholder.com/150?text=Giraffe',
        date: DateTime.now().subtract(const Duration(days: 7)),
        location: 'PLACEHOLDER LOCATION',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Gallery'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: photos.isEmpty
          ? const Center(
        child: Text('No photos yet. Start capturing wildlife!'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          return AnimalPhotoCard(photo: photos[index]);
        },
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 2),
    );
  }
}