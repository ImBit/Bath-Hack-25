import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';

class JournalEntry {
  final String name;
  final String imageUrl;
  final String level;
  final int currentProgress;
  final int maxProgress;

  JournalEntry({
    required this.name,
    required this.imageUrl,
    required this.level,
    required this.currentProgress,
    required this.maxProgress,
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
    ),
    JournalEntry(
      name: 'Eagle',
      imageUrl:
          'https://static.vecteezy.com/system/resources/previews/010/345/372/non_2x/eagle-bird-color-icon-illustration-vector.jpg',
      level: 'Level 2',
      currentProgress: 75,
      maxProgress: 100,
    ),
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
              return Card(
                color: Colors.grey[300],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
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
                            Text(
                              entry.name,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.start,
                            ),

                            // Level + progress bar
                            Row(
                              children: [
                                SizedBox(
                                  width: 75,
                                  child: Text(
                                    entry.level,
                                    style: TextStyle(fontSize: 16),
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
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                      ),
                                      // Progress bar
                                      FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor:
                                            entry.currentProgress /
                                                entry.maxProgress,
                                        child: Container(
                                          height: 25,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(5),
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
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 0),
    );
  }
}
