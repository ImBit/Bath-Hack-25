import 'package:flutter/material.dart';
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
  final String imageUrl;
  final String level;
  final int currentProgress;
  final int maxProgress;
  final Rarity rarity;
  final String description;

  JournalEntry({
    required this.name,
    required this.imageUrl,
    required this.level,
    required this.currentProgress,
    required this.maxProgress,
    required this.rarity,
    required this.description,
  });
}

class JournalView extends StatefulWidget {
  const JournalView({super.key});

  @override
  State<JournalView> createState() => _JournalViewState();
}

class _JournalViewState extends State<JournalView> {
  final List<JournalEntry> entries = [
    JournalEntry(
        name: 'Pigeon',
        imageUrl:
            'https://static.vecteezy.com/system/resources/previews/010/345/372/non_2x/pigeon-bird-color-icon-illustration-vector.jpg',
        level: 'Level 1',
        currentProgress: 50,
        maxProgress: 100,
        rarity: Rarity.common,
        description:
            'Feared by crumbs, respected by couriers, the **rock pigeon** (*Columba livia*) is a master of the urban biome. Descended from wild cliff-dwelling ancestors, it now commands the skies of cityscapes worldwide, nesting on ledges and high-rises as if they were ancient seaside cliffs.\n\nWith a built-in biological compass, it can sense Earth’s magnetic fields and the position of the sun, allowing it to navigate home from over 1,000 miles away—a skill so precise, humans once relied on it in war.'),
    JournalEntry(
        name: 'Fox',
        imageUrl:
            'https://banner2.cleanpng.com/20230504/liw/transparent-fox-cute-fox-little-fox-cute-cartoon-1711145904475.webp',
        level: 'Level 2',
        currentProgress: 75,
        maxProgress: 100,
        rarity: Rarity.uncommon,
        description:
            'Slinking through twilight like a living shadow, the **red fox** (*Vulpes vulpes*) is nature\'s stealth specialist. With ears fine-tuned to the rustle of a mouse beneath snow and paws padded for silent pursuit, it hunts with uncanny precision—sometimes leaping high into the air to pounce with acrobatic flair.\n\nFound from Arctic tundra to suburban sprawl, this adaptable creature has the widest range of any wild canid, thriving anywhere stealth and cunning can earn a meal.'),
    // Add more entries as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ListView.builder(
            itemCount: entries.length, // Number of entries to display
            itemBuilder: (context, index) {
              final entry = entries[index];
              return GestureDetector(
                onTap: () {
                  showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => Dialog(
                      insetPadding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 20,
                        bottom: 100,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            AnimalDetails(entry: entry),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              // Type: Bird
                              child: MarkdownBody(
                                data: 'Type: **Bird**',
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
                                  MarkdownBody(
                                    data: entry.description,
                                    // styleSheet: MarkdownStyleSheet(
                                    //   p: const TextStyle(
                                    //     fontSize: 16,
                                    //     color: Colors.black,
                                    //   ),
                                    // ),
                                  ),
                                  const Divider(),
                                  const Text(
                                    'Recent sightings',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Card(
                                    color: Colors.grey[300],
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          const Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.calendar_month),
                                                  SizedBox(width: 8),
                                                  Text("1 Apr 2025 (4 days ago)"),
                                                ],
                                              ),
                                              SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(Icons.location_on),
                                                  SizedBox(width: 8),
                                                  Text("University of Bath"),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Expanded(
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: const Image(
                                                  image: AssetImage('assets/pigeon.webp'),
                                                  height: 75,
                                                  width: 75,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),                                    
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
                    ),
                  );
                },
                child: Card(
                  color: Colors.grey[300],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: AnimalDetails(
                      entry: entry,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 1),
    );
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
          backgroundImage: NetworkImage(entry.imageUrl),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              Row(
                children: [
                  Text(
                    entry.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                  ),
                  // Rarity
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
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
        // TextButton(
        //   onPressed: () => showDialog<String>(
        //     context: context,
        //     builder: (BuildContext context) => Dialog(
        //       insetPadding: const EdgeInsets.only(
        //         left: 20,
        //         right: 20,
        //         top: 20,
        //         bottom: 100,
        //       ),
        //       child: Padding(
        //         padding: const EdgeInsets.all(8.0),
        //         child: Column(
        //           mainAxisSize: MainAxisSize.min,
        //           mainAxisAlignment: MainAxisAlignment.center,
        //           children: <Widget>[
        //             // Expanded(child: Text('This is a typical dialog.')),
        //             AnimalDetails(entry: entry),
        //             const SizedBox(height: 15),
        //             TextButton(
        //               onPressed: () {
        //                 Navigator.pop(context);
        //               },
        //               child: const Text('Close'),
        //             ),
        //           ],
        //         ),
        //       ),
        //     ),
        //   ),
        //   child: const Text('Show'),
        // ),
      ],
    );
  }
}
