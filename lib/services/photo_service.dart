import '../models/animal_photo.dart';

class PhotoService {
  // This would be replaced with actual database/API calls
  Future<List<AnimalPhoto>> getPhotos() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock data
    return [
      AnimalPhoto(
        id: '1',
        name: 'Lion',
        imageUrl: 'https://via.placeholder.com/150?text=Lion',
        date: DateTime.now().subtract(const Duration(days: 2)),
        location: 'PLACEHOLDER_LOCATION',
      ),
      AnimalPhoto(
        id: '2',
        name: 'Elephant',
        imageUrl: 'https://via.placeholder.com/150?text=Elephant',
        date: DateTime.now().subtract(const Duration(days: 5)),
        location: 'PLACEHOLDER_LOCATION',
      ),
      AnimalPhoto(
        id: '3',
        name: 'Giraffe',
        imageUrl: 'https://via.placeholder.com/150?text=Giraffe',
        date: DateTime.now().subtract(const Duration(days: 7)),
        location: 'PLACEHOLDER_LOCATION',
      ),
    ];
  }

  Future<void> addPhoto(AnimalPhoto photo) async {
    // SAVE PHOTO TO DATABASE?
    await Future.delayed(const Duration(seconds: 1));
    // IMPLEMENTATION HERE
  }
}