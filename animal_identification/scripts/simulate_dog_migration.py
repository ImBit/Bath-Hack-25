import firebase_admin
from firebase_admin import credentials, firestore
import random
import datetime
import uuid
import time

# Initialize Firebase (you'll need to provide your own credentials file)
# If you're not using Firebase, you can modify the database connection code
def initialize_firebase():
    try:
        # Use service account credentials
        cred = credentials.Certificate("path_to_your_serviceAccountKey.json")
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        return db
    except Exception as e:
        print(f"Firebase initialization error: {e}")
        print("Continuing in simulation mode without database connection")
        return None

def simulate_dog_migration():
    print("Starting dog migration simulation...")

    # Starting coordinates
    start_lat = 51.3781017
    start_lng = -2.3596817

    # Animal classification ID (domestic dog)
    animal_id = "eznjYhDJrqFSTCOXZiM2"

    # User ID who took the photos
    user_id = "568be83a-562d-4386-85aa-6e5d41696029"

    # Get database connection (or None if in simulation mode)
    db = initialize_firebase()

    # Generate dates spanning 10 days from current date
    current_date = datetime.datetime.now()
    start_date = current_date - datetime.timedelta(days=10)

    # Generate 100 dog sightings
    generated_data = []

    for i in range(1, 101):
        # Calculate time progression (0-1 range)
        time_factor = i / 100

        # Calculate days since start (distributed over 10 days)
        days_since_start = time_factor * 10

        # Generate timestamp
        timestamp = start_date + datetime.timedelta(days=days_since_start)

        # Calculate position spread based on time progression
        # Dogs spread +1 degree west and ±1 degree north/south over time
        lng_offset = -1 * time_factor  # Moving west (negative)

        # Random north/south movement within range determined by time
        max_lat_offset = time_factor  # Maximum offset grows with time
        lat_offset = random.uniform(-max_lat_offset, max_lat_offset)

        # Add some randomness to movement
        random_lat = random.uniform(-0.05, 0.05)  # Small random variation
        random_lng = random.uniform(-0.05, 0.05)  # Small random variation

        # Calculate final position
        final_lat = start_lat + lat_offset + random_lat
        final_lng = start_lng + lng_offset + random_lng

        # Create data entry
        photo_data = {
            "userId": user_id,
            "animalClassification": animal_id,
            "timestamp": timestamp,
            "location": [final_lat, final_lng],
            "encryptedImageData": f"mock_dog_image_{i}",  # Placeholder for encrypted image data
            "id": str(uuid.uuid4()),  # Generate random ID for the photo
        }

        generated_data.append(photo_data)

        # If connected to database, add document
        if db:
            try:
                doc_ref = db.collection("photos").document(photo_data["id"])
                doc_ref.set(photo_data)
                print(f"Added entry {i}/100: Dog at {final_lat}, {final_lng}")
            except Exception as e:
                print(f"Error adding document {i}: {e}")
        else:
            # Print simulation output
            print(f"Simulation {i}/100: Dog at {final_lat}, {final_lng} on {timestamp.strftime('%Y-%m-%d %H:%M:%S')}")

    # Output summary of what was generated
    print("\nSimulation Complete!")
    print(f"Generated 100 dog sightings over 10 days")
    print(f"Starting location: {start_lat}, {start_lng}")
    print(f"Final locations spread approximately ±1 degree N/S and 1 degree W")

    # If not connected to database, output CSV option
    if not db:
        print("\nDatabase connection wasn't established.")
        print("Would you like to save the data as CSV? (yes/no)")
        response = input().strip().lower()
        if response == "yes":
            save_as_csv(generated_data)

def save_as_csv(data):
    import csv

    filename = f"dog_migration_data_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"

    try:
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            # Write header
            writer.writerow(['id', 'userId', 'animalClassification', 'timestamp', 'latitude', 'longitude', 'encryptedImageData'])

            # Write data
            for entry in data:
                writer.writerow([
                    entry['id'],
                    entry['userId'],
                    entry['animalClassification'],
                    entry['timestamp'].strftime('%Y-%m-%d %H:%M:%S'),
                    entry['location'][0],
                    entry['location'][1],
                    entry['encryptedImageData']
                ])

        print(f"Data saved to {filename}")
    except Exception as e:
        print(f"Error saving CSV: {e}")

if __name__ == "__main__":
    simulate_dog_migration()