import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/objects/photo_object.dart';
import '../screens/journal_screen.dart';

class AnimalService {
  /// Generates an AnimalObject with appropriate properties when a new animal is detected
  /// This should be called when an animal is first registered in the system
  static Future<AnimalObject> generateAnimalObject({
    required String animalName,
    required String? species,
    required PhotoObject firstPhoto,
    required Rarity rarity,
  }) async {
    // Get current timestamp for the description
    final timestamp = DateTime.now().toUtc().toString().split('.')[0];

    // Fetch description and image in parallel
    final descriptionFuture = fetchAnimalDescription(animalName);
    final imageFuture = fetchAnimalImage(animalName);

    // Wait for both to complete
    final description = await descriptionFuture;
    final imageUrl = await imageFuture;

    // Use fetched description or create a default one
    String finalDescription;
    if (description != null && description.isNotEmpty) {
      finalDescription = description;

      // Add timestamp information
      finalDescription += "\n\nFirst spotted on $timestamp UTC.";

      // If species is provided and different from the name, add it to description
      if (species != null && species.isNotEmpty && species.toLowerCase() != animalName.toLowerCase()) {
        finalDescription += "\n\nScientific name: $species";
      }
    } else {
      // Create description template if fetching failed
      finalDescription = "This $animalName was first spotted on $timestamp UTC.";

      // If species is provided and different from the name, add it to description
      if (species != null && species.isNotEmpty && species.toLowerCase() != animalName.toLowerCase()) {
        finalDescription += "\n\nScientific name: $species.";
      }

      // Add placeholder text
      finalDescription += "\n\nMore information about this species will be added as you encounter it more frequently.";
    }

    // Create the AnimalObject with the fetched image URL or the first photo path as fallback
    return AnimalObject(
        id: null,  // This will be assigned by Firestore when saved
        name: animalName,
        species: species ?? animalName,
        description: finalDescription,
        imageUrl: imageUrl ?? firstPhoto.photoPath, // Use fetched image or photo path
        rarity: rarity.toString().split('.').last // Convert enum to string
    );
  }

  /// Updates an existing AnimalObject with new information
  static Future<AnimalObject> updateAnimalObject({
    required AnimalObject existingAnimal,
    required PhotoObject newPhoto,
    required int totalPhotoCount,
  }) async {
    // Keep the existing image URL if it exists
    String? imageUrl = existingAnimal.imageUrl;

    // If no image URL exists or we want to update it with a newer photo
    if (imageUrl == null || imageUrl.isEmpty) {
      // Try to fetch an image from the internet
      String? fetchedImageUrl = await fetchAnimalImage(existingAnimal.name);
      imageUrl = fetchedImageUrl ?? newPhoto.photoPath;
    }

    // Determine rarity based on total photo count
    Rarity calculatedRarity;
    if (totalPhotoCount >= 20) {
      calculatedRarity = Rarity.common;
    } else if (totalPhotoCount >= 10) {
      calculatedRarity = Rarity.uncommon;
    } else if (totalPhotoCount >= 5) {
      calculatedRarity = Rarity.rare;
    } else {
      calculatedRarity = Rarity.legendary;
    }

    // Convert the rarity enum to string
    String rarityString = calculatedRarity.toString().split('.').last;

    // Create updated animal object
    return AnimalObject(
        id: existingAnimal.id,
        name: existingAnimal.name,
        species: existingAnimal.species,
        description: existingAnimal.description,
        imageUrl: imageUrl,
        rarity: rarityString
    );
  }

  /// Fetch animal description from the internet (similar to the Python script)
  static Future<String?> fetchAnimalDescription(String animalName) async {
    try {
      // Try Wikipedia API first as it's more reliable
      final encodedName = Uri.encodeComponent(animalName.replaceAll(' ', '_'));
      final wikiUrl = 'https://en.wikipedia.org/api/rest_v1/page/summary/$encodedName';

      final response = await http.get(
        Uri.parse(wikiUrl),
        headers: {
          'User-Agent': 'AnimalJournal/1.0 (Flutter App; research purposes)'
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['extract'] != null && data['extract'].toString().isNotEmpty) {
          // Get the extract and format it
          String extract = data['extract'].toString();

          // Split into sentences and take the first 3
          final sentences = extract.split(RegExp(r'[.!?]+\s*'));
          final cleanSentences = sentences
              .where((s) => s.trim().isNotEmpty)
              .take(3)
              .map((s) => s.trim())
              .toList();

          if (cleanSentences.isNotEmpty) {
            return cleanSentences.join('. ') + '.';
          }
        }
      }

      // If Wikipedia fails, try DuckDuckGo API as backup (similar to Python script)
      final query = Uri.encodeComponent('$animalName species description habitat');
      final ddgUrl = 'https://api.duckduckgo.com/?q=$query&format=json';

      final ddgResponse = await http.get(
        Uri.parse(ddgUrl),
        headers: {
          'User-Agent': 'AnimalJournal/1.0 (Flutter App; research purposes)'
        },
      ).timeout(const Duration(seconds: 10));

      if (ddgResponse.statusCode == 200) {
        final data = jsonDecode(ddgResponse.body);

        // Check for abstract
        if (data['Abstract'] != null && data['Abstract'].toString().isNotEmpty) {
          String abstract = data['Abstract'].toString();
          final sentences = abstract.split(RegExp(r'[.!?]+\s*'));
          final cleanSentences = sentences
              .where((s) => s.trim().isNotEmpty)
              .take(3)
              .map((s) => s.trim())
              .toList();

          if (cleanSentences.isNotEmpty) {
            return cleanSentences.join('. ') + '.';
          }
        }

        // Try related topics
        if (data['RelatedTopics'] != null && data['RelatedTopics'] is List && (data['RelatedTopics'] as List).isNotEmpty) {
          for (var topic in data['RelatedTopics']) {
            if (topic['Text'] != null && topic['Text'].toString().isNotEmpty) {
              String text = topic['Text'].toString();
              final sentences = text.split(RegExp(r'[.!?]+\s*'));
              final cleanSentences = sentences
                  .where((s) => s.trim().isNotEmpty)
                  .take(3)
                  .map((s) => s.trim())
                  .toList();

              if (cleanSentences.isNotEmpty) {
                return cleanSentences.join('. ') + '.';
              }
            }
          }
        }
      }

      // If all APIs fail, return a generic description
      return '''
$animalName is a fascinating animal species found in various habitats around the world.

These animals are known for their distinctive characteristics and behaviors. As you discover more about them through your observations, this journal will be updated with more detailed information.

Keep taking photos to level up your knowledge of this species!
''';
    } catch (e) {
      print("Error fetching animal description: $e");
      return null;
    }
  }

  /// Fetch an image URL for the animal from the internet
  static Future<String?> fetchAnimalImage(String animalName) async {
    try {
      // Try to get an image from Wikipedia
      final encodedName = Uri.encodeComponent(animalName.replaceAll(' ', '_'));
      final wikiUrl = 'https://en.wikipedia.org/api/rest_v1/page/summary/$encodedName';

      final response = await http.get(
        Uri.parse(wikiUrl),
        headers: {
          'User-Agent': 'AnimalJournal/1.0 (Flutter App; research purposes)'
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check for thumbnail image
        if (data['thumbnail'] != null &&
            data['thumbnail']['source'] != null &&
            data['thumbnail']['source'].toString().isNotEmpty) {
          return data['thumbnail']['source'].toString();
        }

        // Check for main image
        if (data['originalimage'] != null &&
            data['originalimage']['source'] != null &&
            data['originalimage']['source'].toString().isNotEmpty) {
          return data['originalimage']['source'].toString();
        }
      }

      // If Wikipedia fails, could try other sources
      // For now, return null and the caller will use the photo path
      return null;
    } catch (e) {
      print("Error fetching animal image: $e");
      return null;
    }
  }
}