import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                      'https://avatars.githubusercontent.com/u/13787163?v=4'),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Heath',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: ProfileStatsRow(),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, my name is Heath. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    children: [
                      SizedBox(
                        width: (MediaQuery.of(context).size.width) / 3,
                        height: (MediaQuery.of(context).size.width) / 3,
                        child: const Image(
                          image: NetworkImage(
                              'https://i.ytimg.com/vi/czR6DrMptJE/hq720.jpg?sqp=-oaymwEhCK4FEIIDSFryq4qpAxMIARUAAAAAGAElAADIQj0AgKJD&rs=AOn4CLBm-s4RSY9BGKY3Km3KS0ASs_RaiQ'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width) / 3,
                        height: (MediaQuery.of(context).size.width) / 3,
                        child: const Image(
                          image: NetworkImage(
                              'https://assets.tiltify.com/uploads/media_type/image/203025/blob-09636982-a21a-494b-bbe4-3692c2720ae3.jpeg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width) / 3,
                        height: (MediaQuery.of(context).size.width) / 3,
                        child: const Image(
                          image: NetworkImage(
                              'https://media.gettyimages.com/id/842992554/photo/dove-with-glasses.jpg?s=612x612&w=gi&k=20&c=-Q6F36h_VDaZLVIh90CAfvP3R-ICpHKyjZ5e2wKNqos='),
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width) / 3,
                        height: (MediaQuery.of(context).size.width) / 3,
                        child: const Image(
                          image: NetworkImage(
                              'https://raspberriescards.com/cdn/shop/files/BirdSticker.jpg?v=1696778689'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width) / 3,
                        height: (MediaQuery.of(context).size.width) / 3,
                        child: const Image(
                          image: NetworkImage(
                              'https://i.ytimg.com/vi/czR6DrMptJE/hq720.jpg?sqp=-oaymwEhCK4FEIIDSFryq4qpAxMIARUAAAAAGAElAADIQj0AgKJD&rs=AOn4CLBm-s4RSY9BGKY3Km3KS0ASs_RaiQ'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width) / 3,
                        height: (MediaQuery.of(context).size.width) / 3,
                        child: const Image(
                          image: NetworkImage(
                              'https://assets.tiltify.com/uploads/media_type/image/203025/blob-09636982-a21a-494b-bbe4-3692c2720ae3.jpeg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width) / 3,
                        height: (MediaQuery.of(context).size.width) / 3,
                        child: const Image(
                          image: NetworkImage(
                              'https://media.gettyimages.com/id/842992554/photo/dove-with-glasses.jpg?s=612x612&w=gi&k=20&c=-Q6F36h_VDaZLVIh90CAfvP3R-ICpHKyjZ5e2wKNqos='),
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width) / 3,
                        height: (MediaQuery.of(context).size.width) / 3,
                        child: const Image(
                          image: NetworkImage(
                              'https://raspberriescards.com/cdn/shop/files/BirdSticker.jpg?v=1696778689'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width) / 3,
                        height: (MediaQuery.of(context).size.width) / 3,
                        child: const Image(
                          image: NetworkImage(
                              'https://i.ytimg.com/vi/czR6DrMptJE/hq720.jpg?sqp=-oaymwEhCK4FEIIDSFryq4qpAxMIARUAAAAAGAElAADIQj0AgKJD&rs=AOn4CLBm-s4RSY9BGKY3Km3KS0ASs_RaiQ'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width) / 3,
                        height: (MediaQuery.of(context).size.width) / 3,
                        child: const Image(
                          image: NetworkImage(
                              'https://assets.tiltify.com/uploads/media_type/image/203025/blob-09636982-a21a-494b-bbe4-3692c2720ae3.jpeg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width) / 3,
                        height: (MediaQuery.of(context).size.width) / 3,
                        child: const Image(
                          image: NetworkImage(
                              'https://media.gettyimages.com/id/842992554/photo/dove-with-glasses.jpg?s=612x612&w=gi&k=20&c=-Q6F36h_VDaZLVIh90CAfvP3R-ICpHKyjZ5e2wKNqos='),
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width) / 3,
                        height: (MediaQuery.of(context).size.width) / 3,
                        child: const Image(
                          image: NetworkImage(
                              'https://raspberriescards.com/cdn/shop/files/BirdSticker.jpg?v=1696778689'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
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
}

class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatColumn('12', 'Photos'),
        _buildDivider(),
        _buildStatColumn('5', 'Species'),
        _buildDivider(),
        _buildStatColumn('3', 'Badges'),
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
