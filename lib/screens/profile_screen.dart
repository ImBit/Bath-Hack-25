import 'package:flutter/material.dart';
import '../database/database_management.dart';
import '../database/objects/user_object.dart';
import '../database/objects/photo_object.dart';
import '../services/user_manager.dart';
import '../widgets/bottom_navigation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<PhotoObject> _userPhotos = [];
  bool _isLoading = true;
  String _photoCount = "0";
  String _speciesCount = "0";

  @override
  void initState() {
    super.initState();
    _loadUserPhotos();
  }

  Future<void> _loadUserPhotos() async {
    setState(() {
      _isLoading = true;
    });

    final currentUser = UserManager.getCurrentUser;
    if (currentUser != null && currentUser.id != null) {
      try {
        final photos = await FirestoreService.getPhotosByUser(currentUser.id!);

        // Count unique species
        final Set<String?> uniqueSpecies = {};
        for (var photo in photos) {
          if (photo.animalClassification != null) {
            uniqueSpecies.add(photo.animalClassification);
          }
        }

        setState(() {
          _userPhotos = photos;
          _photoCount = photos.length.toString();
          _speciesCount = uniqueSpecies.length.toString();
          _isLoading = false;
        });
      } catch (e) {
        print("Error loading user photos: $e");
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: UserManager.getActiveUserProfilePicture(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          UserManager.getCurrentUser?.username ?? 'Guest',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          // Create a text editing controller with the current username
                          final TextEditingController usernameController = TextEditingController(
                              text: UserManager.getCurrentUser?.username ?? 'Guest'
                          );

                          // Handle edit profile action
                          showDialog<String>(
                            context: context,
                            builder: (BuildContext context) => Dialog(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const Text(
                                      'Update Username',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: usernameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Username',
                                        hintText: 'Enter your new username',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    Row(
                                      children: [
                                        const Spacer(),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            // Get current user ID
                                            final currentUser = UserManager.getCurrentUser;
                                            if (currentUser != null && currentUser.id != null) {
                                              final newUsername = usernameController.text.trim();

                                              if (newUsername.isEmpty) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Username cannot be empty'))
                                                );
                                                return;
                                              }

                                              // Show loading indicator
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (BuildContext context) => const Center(
                                                  child: CircularProgressIndicator(),
                                                ),
                                              );

                                              // Update username in Firestore
                                              final success = await FirestoreService.updateUsername(
                                                  currentUser.id!,
                                                  newUsername
                                              );

                                              // Close loading dialog
                                              Navigator.pop(context);

                                              if (success) {
                                                // Update current user in UserManager
                                                UserManager.setCurrentUser(
                                                    UserObject(
                                                      id: currentUser.id,
                                                      username: newUsername,
                                                      password: currentUser.password,
                                                      // Include any other fields your UserObject has
                                                    )
                                                );

                                                // Close the edit dialog
                                                Navigator.pop(context);

                                                // Add setState to trigger UI update
                                                setState(() {
                                                  // The setState will cause the widget to rebuild
                                                  // with the new username from UserManager
                                                });

                                                // Show success message
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Username updated successfully'))
                                                );
                                              } else {
                                                // Show error message
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Username is already taken'))
                                                );
                                              }
                                            } else {
                                              // Handle case when user is not logged in
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('You need to be logged in to update your username'))
                                              );
                                            }
                                          },
                                          child: const Text('Save'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: ProfileStatsRow(
                    photoCount: _photoCount,
                    speciesCount: _speciesCount,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Wildlife Collection',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  _userPhotos.isEmpty
                      ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No photos yet. Capture some wildlife!',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                      : Wrap(
                    children: _buildPhotoGrid(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 3),
    );
  }

  List<Widget> _buildPhotoGrid() {
    return _userPhotos.map((photo) {
      return GestureDetector(
        onTap: () {
          // Handle photo tap - maybe show details or full screen view
          _showPhotoDetails(photo);
        },
        child: SizedBox(
          width: MediaQuery.of(context).size.width / 3,
          height: MediaQuery.of(context).size.width / 3,
          child: photo.encryptedImageData != null && photo.encryptedImageData!.isNotEmpty
              ? Image(
            image: photo.getImageProvider() ??
                const AssetImage('assets/images/placeholder_animal.png'),
            fit: BoxFit.cover,
          )
              : Image.asset(
            'assets/images/placeholder_animal.png',
            fit: BoxFit.cover,
          ),
        ),
      );
    }).toList();
  }

  void _showPhotoDetails(PhotoObject photo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Photo Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.width * 0.8,
                      child: photo.encryptedImageData != null
                          ? Image(
                        image: photo.getImageProvider() ??
                            const AssetImage('assets/images/placeholder_animal.png'),
                        fit: BoxFit.contain,
                      )
                          : Image.asset(
                        'assets/images/placeholder_animal.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Date: ${photo.timestamp.toString().split('.')[0]}'),
                  if (photo.animalClassification != null)
                    FutureBuilder<AnimalObject?>(
                      future: FirestoreService.getAnimalById(photo.animalClassification!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text('Loading animal information...');
                        }

                        if (snapshot.hasData && snapshot.data != null) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text('Species: ${snapshot.data!.name}'),
                              Text('Rarity: ${snapshot.data!.rarity}'),
                              const SizedBox(height: 8),
                              Text('Description: ${snapshot.data!.description}'),
                            ],
                          );
                        }

                        return const Text('No animal classification available');
                      },
                    ),
                  const SizedBox(height: 16),
                  if (photo.location != null && photo.location!.length >= 2)
                    Text('Location: ${photo.location![0]}, ${photo.location![1]}'),
                  const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ProfileStatsRow extends StatelessWidget {
  final String photoCount;
  final String speciesCount;

  const ProfileStatsRow({
    super.key,
    required this.photoCount,
    required this.speciesCount
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatColumn(photoCount, 'Photos'),
        _buildDivider(),
        _buildStatColumn(speciesCount, 'Species'),
        _buildDivider(),
        _buildStatColumn('3', 'Badges'), // This could be dynamic too
      ],
    );
  }

  Column _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.withOpacity(0.5),
    );
  }
}