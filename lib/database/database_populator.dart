import 'dart:convert';
import 'dart:io';
import 'package:animal_conservation/screens/journal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'database_management.dart';
import 'objects/photo_object.dart';

class AnimalDatabasePopulator {

  // Function to load the animal data from a JSON file
  Future<List<String>> _loadAnimalDataFromJson() async {
    try {
      final String jsonData = await rootBundle.loadString('lib/database/taxonomy_release.txt');
      final List<dynamic> jsonList = json.decode(jsonData);
      return jsonList.cast<String>();

      // Option 2: If you need to read from a file in the app's documents directory
      /*
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/xxx/xxx.json');
      if (await file.exists()) {
        final String contents = await file.readAsString();
        final List<dynamic> jsonList = json.decode(contents);
        return jsonList.cast<String>();
      }
      */
    } catch (e) {
      print("Error loading animal data: $e");
    }
    return [];
  }

  // Parse a single line of data into an AnimalObject
  AnimalObject _parseAnimalLine(String line) {
    final parts = line.split(';');

    if (parts.length < 7) {
      // Not enough parts, add empty fields if needed
      while (parts.length < 7) {
        parts.add('');
      }
    }

    final id = parts[0];
    final species = parts[1]; // This is the taxonomy class (mammalia, aves, etc.)
    final name = parts[6].isNotEmpty ? parts[6] : "${parts[5]} species"; // Use last non-empty taxonomy or "species"

    // Create a description from the taxonomy
    final description = _buildDescriptionFromTaxonomy(parts);

    return AnimalObject(
      id: id,
      name: name,
      species: species,
      rarity: Rarity.common.name,
      description: description
    );
  }

  // Build a description from the taxonomy data
  String _buildDescriptionFromTaxonomy(List<String> parts) {
    List<String> taxonomy = [];

    // Map indices to taxonomy levels
    final Map<int, String> taxonomyLevels = {
      1: "Class",
      2: "Order",
      3: "Family",
      4: "Genus",
      5: "Species"
    };

    for (int i = 1; i < 6; i++) {
      if (parts.length > i && parts[i].isNotEmpty) {
        taxonomy.add("${taxonomyLevels[i]}: ${parts[i]}");
      }
    }

    if (taxonomy.isEmpty) {
      return "No taxonomic information available";
    }

    return taxonomy.join("\n");
  }

  // Main function to populate the database
  Future<void> populateAnimalDatabase() async {
    try {
      final List<String> animalDataLines = await _loadAnimalDataFromJson();

      if (animalDataLines.isEmpty) {
        print("No animal data found");
        return;
      }

      print("Starting to populate database with ${animalDataLines.length} animals...");
      int success = 0;
      int failed = 0;

      for (var line in animalDataLines) {
        final AnimalObject animal = _parseAnimalLine(line);
        String? result = await FirestoreService.saveAnimal(animal);

        if (result != null) {
          success++;
          if (success % 100 == 0) {
            print("Processed $success animals...");
          }
        } else {
          failed++;
          print("Failed to save animal: ${animal.name}");
        }
      }

      print("Database population completed!");
      print("Successfully added: $success animals");
      print("Failed to add: $failed animals");

    } catch (e) {
      print("Error populating database: $e");
    }
  }
}

// Example usage in your app
void populateDatabase() async {
  final populator = AnimalDatabasePopulator();
  await populator.populateAnimalDatabase();
}