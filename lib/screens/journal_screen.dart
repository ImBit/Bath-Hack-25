import 'package:animal_conservation/services/user_manager.dart';
import 'package:flutter/material.dart';
import '../database/database_management.dart';
import '../database/objects/photo_object.dart';
import '../services/animal_levelling_manager.dart';
import '../widgets/bottom_navigation.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

enum Rarity {
  common,
  uncommon,
  rare,
  legendary,
}

// Rarity to color mapping
const rarityColors = {
  Rarity.common: Colors.green,
  Rarity.uncommon: Colors.blue,
  Rarity.rare: Colors.purple,
  Rarity.legendary: Colors.red,
};

// Rarity to string mapping
const rarityStrings = {
  Rarity.common: 'Common',
  Rarity.uncommon: 'Uncommon',
  Rarity.rare: 'Rare',
  Rarity.legendary: 'Legendary',
};

class JournalEntry {
  final String name;
  final ImageProvider<Object> image;
  final String level;
  final int currentProgress;
  final int maxProgress;
  final Rarity rarity;
  final String description;
  final String type;
  final List<PhotoObject> photos; // Added to store associated photos

  JournalEntry({
    required this.name,
    required this.image,
    required this.level,
    required this.currentProgress,
    required this.maxProgress,
    required this.rarity,
    required this.description,
    required this.type,
    required this.photos,
  });
}

class JournalView extends StatefulWidget {
  const JournalView({super.key});

  @override
  State<JournalView> createState() => _JournalViewState();
}

class _JournalViewState extends State<JournalView>
    with SingleTickerProviderStateMixin {
  late Animation<double> animation;
  late AnimationController controller;
  List<JournalEntry> entries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        duration: const Duration(seconds: 100000), vsync: this);
    animation = Tween<double>(begin: 0, end: 4000).animate(controller)
      ..addListener(() {
        setState(() {
          // The state that has changed here is the animation object's value.
        });
        if (controller.isCompleted) {
          controller.repeat();
        }
      });
    controller.forward();

    // Load journal entries
    _loadJournalEntries();
  }

  // Method to determine rarity based on animal name/species or other factors
  Rarity _determineRarity(AnimalObject animal) {
    // This is a simplified implementation - can be enhanced based on actual requirements
    switch (animal.species.toLowerCase()) {
      case 'bird':
        return Rarity.common;
      case 'mammal':
        return Rarity.uncommon;
      case 'reptile':
        return Rarity.rare;
      case 'amphibian':
      case 'fish':
        return Rarity.legendary;
      default:
        return Rarity.common;
    }
  }

  // Load journal entries from Firestore
  Future<void> _loadJournalEntries() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get current user ID from provider
      final userId = UserManager.getUserId();

      if (userId == null) {
        print("No user logged in");
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Get photos with animal data for the current user
      final photosWithAnimalData = await FirestoreService.getPhotosWithAnimalData(userId);

      // Group photos by animal
      Map<String, List<Map<String, dynamic>>> animalGroups = {};

      for (var item in photosWithAnimalData) {
        final photo = item['photo'] as PhotoObject;
        final animal = item['animal'] as AnimalObject?;

        if (animal != null) {
          if (!animalGroups.containsKey(animal.id)) {
            animalGroups[animal.id!] = [];
          }
          animalGroups[animal.id]!.add(item);
        }
      }

      // Create journal entries from grouped data
      List<JournalEntry> loadedEntries = [];

      for (var animalId in animalGroups.keys) {
        final animalData = animalGroups[animalId]!;
        final animal = animalData.first['animal'] as AnimalObject;
        final photos = animalData.map((item) => item['photo'] as PhotoObject).toList();

        // Calculate progress based on number of photos
        final photoCount = photos.length;
        final maxPhotos = LevellingManager.getPhotosNeededForNextLevel(photoCount);
        final currentProgress = LevellingManager.getProgress(photoCount);
        final level = "Level ${LevellingManager.getLevel(photoCount)}";

        // Determine image to use
        ImageProvider<Object> image;
        if (animal.imageUrl != null && animal.imageUrl!.isNotEmpty) {
          image = NetworkImage(animal.imageUrl!);
        } else if (photos.isNotEmpty && photos.first.getImageProvider() != null) {
          // Use the first photo's image provider as fallback
          image = photos.first.getImageProvider()!;
        } else {
          // Default image if no image available
          image = const AssetImage('assets/default_animal.webp');
        }

        // Create journal entry
        loadedEntries.add(
          JournalEntry(
            name: animal.name,
            image: image,
            level: level,
            currentProgress: currentProgress,
            maxProgress: LevellingManager.getNextLevelRequirement(photoCount),
            rarity: _determineRarity(animal),
            description: animal.description ?? 'No description available.',
            type: animal.species,
            photos: photos,
          ),
        );
      }

      setState(() {
        entries = loadedEntries;
        isLoading = false;
      });

    } catch (e) {
      print("Error loading journal entries: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        backgroundColor: const Color.fromRGBO(255, 166, 0, 1),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.85,
                colors: [
                  Color.fromRGBO(249, 181, 51, 1), // light gold
                  Color.fromRGBO(215, 147, 23, 1), // dark gold
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),

          // Star pattern background
          Positioned.fill(
            child: Image.asset(
              'assets/images/star_pattern.png',
              repeat: ImageRepeat.repeat,
              opacity: const AlwaysStoppedAnimation(0.2),
              alignment: FractionalOffset(animation.value, animation.value / 4),
            ),
          ),

          // Content
          Center(
            child: isLoading
                ? const CircularProgressIndicator()
                : entries.isEmpty
                ? const Center(
              child: Text(
                'No entries found. Start taking photos of animals!',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            )
                : Padding(
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => _showAnimalDetails(entry),
                      child: Card(
                        color: Colors.grey[300],
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: const Alignment(0, 2),
                              stops: const [
                                0, 0.125, 0.125, 0.25, 0.25, 0.375, 0.375, 0.5,
                                0.5, 0.625, 0.625, 0.75, 0.75, 0.875, 0.875, 1
                              ],
                              colors: [
                                Colors.grey[300]!, Colors.grey[300]!,
                                Colors.grey[200]!, Colors.grey[200]!,
                                Colors.grey[300]!, Colors.grey[300]!,
                                Colors.grey[200]!, Colors.grey[200]!,
                                Colors.grey[300]!, Colors.grey[300]!,
                                Colors.grey[200]!, Colors.grey[200]!,
                                Colors.grey[300]!, Colors.grey[300]!,
                                Colors.grey[200]!, Colors.grey[200]!,
                              ],
                              tileMode: TileMode.repeated,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: AnimalDetails(entry: entry),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 1),
    );
  }

  void _showAnimalDetails(JournalEntry entry) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => Dialog(
        insetPadding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 70,
          bottom: 110,
        ),
        child: Stack(
          children: [
            // Dotted background pattern
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/dot.png',
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  AnimalDetails(entry: entry),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: MarkdownBody(
                      data: 'Type: **${entry.type}**',
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: RawScrollbar(
                      child: ListView(children: [
                        // Description section
                        MarkdownBody(
                          data: entry.description,
                        ),
                        const Divider(),
                        const Text(
                          'Recent sightings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Show recent photos
                        ...entry.photos.take(3).map((photo) => _buildRecentSighting(photo)).toList(),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSighting(PhotoObject photo) {
    return Card(
      color: Colors.grey[300],
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month),
                      const SizedBox(width: 8),
                      Text(_formatDate(photo.timestamp)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on),
                      const SizedBox(width: 8),
                      Text('Unknown location'),
                    ],
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: photo.getImageProvider() != null
                  ? Image(
                image: photo.getImageProvider()!,
                height: 75,
                width: 75,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(
                      height: 75,
                      width: 75,
                      color: Colors.grey,
                      child: const Icon(Icons.error),
                    ),
              )
                  : Container(
                height: 75,
                width: 75,
                color: Colors.grey,
                child: const Icon(Icons.photo),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day} ${_getMonth(date.month)} ${date.year}';
    }
  }

  String _getMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class AnimalDetails extends StatelessWidget {
  final JournalEntry entry;

  const AnimalDetails({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: entry.image,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name and Rarity
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                    ),
                  ),
                  // Rarity badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: rarityColors[entry.rarity],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      rarityStrings[entry.rarity]!.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Level + progress bar
              Row(
                children: [
                  SizedBox(
                    width: 75,
                    child: Text(
                      entry.level,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        // Background of the progress bar
                        Container(
                          height: 25,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        // Progress bar
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor:
                          entry.currentProgress / entry.maxProgress,
                          child: Container(
                            height: 25,
                            decoration: BoxDecoration(
                              color: rarityColors[entry.rarity],
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                        // Progress text
                        Positioned.fill(
                          child: Center(
                            child: Text(
                              '${entry.currentProgress}/${entry.maxProgress}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}