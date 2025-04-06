class LevellingManager {
  // Constants
  static const int _photosPerLevel = 5;

  /// Returns the user's level based on the number of photos taken
  /// Level 1: 0-5 photos
  /// Level 2: 5-10 photos
  /// Level 3: 10-15 photos
  /// And so on...
  static int getLevel(int numberOfPhotos) {
    // Photos per level is 5, so divide by 5 and add 1
    // 0-4 photos = level 1
    // 5-9 photos = level 2
    // 10-14 photos = level 3
    return (numberOfPhotos / _photosPerLevel).floor() + 1;
  }

  /// Returns the current progress within the level
  /// This is the number of photos in the current level
  static int getProgress(int numberOfPhotos) {
    int currentLevel = getLevel(numberOfPhotos);
    int minPhotosForCurrentLevel = (currentLevel - 1) * _photosPerLevel;
    return numberOfPhotos - minPhotosForCurrentLevel;
  }

  /// Returns the total photos required to reach the next level
  static int getNextLevelRequirement(int numberOfPhotos) {
    // Always return _photosPerLevel as this is the number of photos needed within each level
    return _photosPerLevel;
  }

  /// Returns the proportion to the next level (0.0 to 1.0)
  /// For example:
  /// - 7 photos = 0.4 (2/5 of the way from level 2 to level 3)
  /// - 12 photos = 0.4 (2/5 of the way from level 3 to level 4)
  static double getLevelProportion(int numberOfPhotos) {
    int currentLevel = getLevel(numberOfPhotos);

    // Calculate the minimum number of photos needed for the current level
    int minPhotosForCurrentLevel = (currentLevel - 1) * _photosPerLevel;

    // Calculate how many photos the user has within the current level
    int photosInCurrentLevel = numberOfPhotos - minPhotosForCurrentLevel;

    // Return the proportion to the next level
    return photosInCurrentLevel / _photosPerLevel;
  }

  /// Returns the total number of photos needed to reach the next level
  static int getPhotosNeededForNextLevel(int numberOfPhotos) {
    int currentLevel = getLevel(numberOfPhotos);
    return currentLevel * _photosPerLevel;
  }

  /// Returns the number of additional photos needed to reach the next level
  static int getAdditionalPhotosNeededForNextLevel(int numberOfPhotos) {
    return getPhotosNeededForNextLevel(numberOfPhotos) - numberOfPhotos;
  }

  /// Returns a formatted string showing progress to the next level
  /// Example: "Level 3 (12/15 photos)"
  static String getFormattedLevelProgress(int numberOfPhotos) {
    int currentLevel = getLevel(numberOfPhotos);
    int photosNeededForNextLevel = getPhotosNeededForNextLevel(numberOfPhotos);

    return "Level $currentLevel ($numberOfPhotos/$photosNeededForNextLevel photos)";
  }
}