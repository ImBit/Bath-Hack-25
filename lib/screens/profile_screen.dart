import 'dart:io';

import 'package:animal_conservation/screens/journal_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database/database_management.dart';
import '../database/objects/user_object.dart';
import '../database/objects/photo_object.dart';
import '../services/image_encryptor.dart';
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
        backgroundColor: const Color.fromRGBO(255, 166, 0, 1),
      ),
      body: Stack(
        children: [
          const PatternedBG(),
          Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(15), // Match card's corner radius
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: const Alignment(0, 2),
                      stops: const [
                        0,
                        0.125,
                        0.125,
                        0.25,
                        0.25,
                        0.375,
                        0.375,
                        0.5,
                        0.5,
                        0.625,
                        0.625,
                        0.75,
                        0.75,
                        0.875,
                        0.875,
                        1
                      ],
                      colors: [
                        Colors.grey[300]!,
                        Colors.grey[300]!,
                        Colors.grey[200]!,
                        Colors.grey[200]!,
                        Colors.grey[300]!,
                        Colors.grey[300]!,
                        Colors.grey[200]!,
                        Colors.grey[200]!,
                        Colors.grey[300]!,
                        Colors.grey[300]!,
                        Colors.grey[200]!,
                        Colors.grey[200]!,
                        Colors.grey[300]!,
                        Colors.grey[300]!,
                        Colors.grey[200]!,
                        Colors.grey[200]!,
                      ],
                      tileMode: TileMode.repeated,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: _editProfilePicture,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundImage: UserManager
                                                    .getCurrentUser?.pfp !=
                                                null &&
                                            UserManager.getCurrentUser!.pfp !=
                                                '--pfp--'
                                        ? UserManager.getCurrentUser!
                                            .getProfilePictureImage()
                                        : const AssetImage(
                                            'assets/images/default_profile.png'),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      height: 24,
                                      width: 24,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          UserManager
                                                  .getCurrentUser?.username ??
                                              'Guest',
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 16),
                                        onPressed: () {
                                          // Your existing username edit code
                                          // ...
                                        },
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: _editBio,
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            UserManager.getCurrentUser?.bio ??
                                                '--empty bio--',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(Icons.edit,
                                            size: 14, color: Colors.grey[600]),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ProfileStatsRow(
                          photoCount: _photoCount,
                          speciesCount: _speciesCount,
                        ),
                      ],
                    ),
                  ),
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
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
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
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 3),
    );
  }

  void _editProfilePicture() async {
    final ImagePicker _picker = ImagePicker();

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      File imageFile = File(image.path);

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get current user
      final currentUser = UserManager.getCurrentUser;
      if (currentUser != null && currentUser.id != null) {
        // Encrypt the image
        String encryptedImage =
            await ImageEncryptor.encryptPngToString(imageFile);

        // Update in Firestore
        final success = await FirestoreService.updateProfilePicture(
            currentUser.id!, encryptedImage);

        // Close loading dialog
        Navigator.pop(context);

        if (success) {
          // Update user locally
          UserObject updatedUser = UserObject(
            id: currentUser.id,
            username: currentUser.username,
            password: currentUser.password,
            bio: currentUser.bio,
            pfp: encryptedImage,
          );

          UserManager.setCurrentUser(updatedUser);

          setState(() {});

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Profile picture updated successfully')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Failed to update profile picture')));
        }
      } else {
        // Close loading dialog
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'You need to be logged in to update your profile picture')));
      }
    } catch (e) {
      print("Error updating profile picture: $e");
      Navigator.of(context, rootNavigator: true).pop(); // Close dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile picture: $e')));
    }
  }

// Add method for editing bio
  void _editBio() {
    // Create a controller with the current bio
    final TextEditingController bioController = TextEditingController(
        text: UserManager.getCurrentUser?.bio ?? '--empty bio--');

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
                'Update Bio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Tell us about yourself',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
                      final currentUser = UserManager.getCurrentUser;
                      if (currentUser != null && currentUser.id != null) {
                        final newBio = bioController.text.trim();

                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        // Update bio in Firestore
                        final success = await FirestoreService.updateBio(
                            currentUser.id!, newBio);

                        // Close loading dialog
                        Navigator.pop(context);

                        if (success) {
                          // Update current user in UserManager
                          UserManager.setCurrentUser(UserObject(
                            id: currentUser.id,
                            username: currentUser.username,
                            password: currentUser.password,
                            bio: newBio,
                            pfp: currentUser.pfp,
                          ));

                          // Close the edit dialog
                          Navigator.pop(context);

                          // Update UI
                          setState(() {});

                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Bio updated successfully')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Failed to update bio')));
                        }
                      } else {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'You need to be logged in to update your bio')));
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
  }

  List<Widget> _buildPhotoGrid() {
    List<Widget> result = _userPhotos.map((photo) {
      return GestureDetector(
        onTap: () {
          // Handle photo tap - maybe show details or full screen view
          _showPhotoDetails(photo);
        },
        child: SizedBox(
          width: MediaQuery.of(context).size.width / 3,
          height: MediaQuery.of(context).size.width / 3,
          child: photo.encryptedImageData != null &&
                  photo.encryptedImageData!.isNotEmpty
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
    // If there are less than 3 photos, fill the remaining space with placeholders
    while (result.length < 3) {
      result.add(
        GestureDetector(
          onTap: () {
            // Handle photo tap - maybe show details or full screen view
          },
          child: SizedBox(
            width: MediaQuery.of(context).size.width / 3,
            height: MediaQuery.of(context).size.width / 3,
          ),
        ),
      );
    }
    return result;
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
                                  const AssetImage(
                                      'assets/images/placeholder_animal.png'),
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
                      future: FirestoreService.getAnimalById(
                          photo.animalClassification!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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
                              Text(
                                  'Description: ${snapshot.data!.description}'),
                            ],
                          );
                        }

                        return const Text('No animal classification available');
                      },
                    ),
                  const SizedBox(height: 16),
                  if (photo.location != null && photo.location!.length >= 2)
                    Text(
                        'Location: ${photo.location![0]}, ${photo.location![1]}'),
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

  const ProfileStatsRow(
      {super.key, required this.photoCount, required this.speciesCount});

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
