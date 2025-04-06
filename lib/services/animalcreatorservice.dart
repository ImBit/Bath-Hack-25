import 'dart:convert';
import 'package:animal_conservation/services/user_manager.dart';
import 'package:http/http.dart' as http;
import '../database/objects/photo_object.dart';
import '../screens/journal_screen.dart';
import '../utils/rarity.dart';

class AnimalService {
  /// Generates an AnimalObject with appropriate properties when a new animal is detected
  /// This should be called when an animal is first registered in the system
  static Future<AnimalObject> generateAnimalObject({
    required String animalName,
    required String? species,
    required PhotoObject firstPhoto,
    required Rarity rarity,
  }) async {
    // Get current date and time for the description
    final now = DateTime.now();
    final formattedDate = _getFormattedDate(now);

    // Get username of the spotter
    final username = UserManager.getCurrentUser?.username ?? "Unknown Explorer";

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

      // Add timestamp information with nicer formatting
      finalDescription += "\n\n**First spotted by $username on $formattedDate.**";

      // If species is provided and different from the name, add it to description
      if (species != null && species.isNotEmpty && species.toLowerCase() != animalName.toLowerCase()) {
        finalDescription += "\n\nScientific name: $species";
      }
    } else {
      // Create description template if fetching failed
      finalDescription = "This $animalName was **first spotted by $username on $formattedDate.**";

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

  static String _getFormattedDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    String day = _getDaySuffix(date.day);
    String month = months[date.month - 1];
    int year = date.year;

    return '$month $day, $year';
  }

// Helper method to add the appropriate suffix to the day
  static String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return '${day}th';
    }

    switch (day % 10) {
      case 1: return '${day}st';
      case 2: return '${day}nd';
      case 3: return '${day}rd';
      default: return '${day}th';
    }
  }

  static Future<AnimalObject> updateAnimalObject({
    required AnimalObject existingAnimal,
    required PhotoObject newPhoto,
    required int totalPhotoCount,
  }) async {
    String? imageUrl = existingAnimal.imageUrl;

    if (imageUrl == null || imageUrl.isEmpty) {
      String? fetchedImageUrl = await fetchAnimalImage(existingAnimal.name);
      imageUrl = fetchedImageUrl ?? newPhoto.photoPath;
    }

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

    String rarityString = calculatedRarity.toString().split('.').last;

    return AnimalObject(
        id: existingAnimal.id,
        name: existingAnimal.name,
        species: existingAnimal.species,
        description: existingAnimal.description,
        imageUrl: imageUrl,
        rarity: rarityString
    );
  }

  static Future<String?> fetchAnimalDescription(String animalName) async {
    try {
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
          String extract = data['extract'].toString();

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

      return '''
      $animalName is an awesome animal!
      ''';
    } catch (e) {
      print("Error fetching animal description: $e");
      return null;
    }
  }

  static Future<String?> fetchAnimalImage(String animalName) async {
    try {
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

        if (data['thumbnail'] != null &&
            data['thumbnail']['source'] != null &&
            data['thumbnail']['source'].toString().isNotEmpty) {
          return data['thumbnail']['source'].toString();
        }

        if (data['originalimage'] != null &&
            data['originalimage']['source'] != null &&
            data['originalimage']['source'].toString().isNotEmpty) {
          return data['originalimage']['source'].toString();
        }
      }
      
      return null;
    } catch (e) {
      print("Error fetching animal image: $e");
      return null;
    }
  }
}