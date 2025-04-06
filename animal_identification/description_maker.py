import os
import requests
import time
import json
import re
import threading
import queue
from random import randint
from concurrent.futures import ThreadPoolExecutor
import traceback

# Lock for thread-safe file operations
file_lock = threading.Lock()
# Lock for thread-safe console output
print_lock = threading.Lock()
# Dictionary to store results across threads
results_dict = {}
# Set to track which animals have already been processed
processed_animals = set()

def safe_print(*args, **kwargs):
    """Thread-safe print function."""
    with print_lock:
        print(*args, **kwargs)

def read_animal_file(file_path):
    """Read the file and extract animal names from each entry."""
    animals = []
    try:
        with open(file_path, 'r') as file:
            for line in file:
                line = line.strip()
                if line:
                    # Split by semicolons and get the last non-empty element
                    parts = line.split(';')
                    # Filter out empty strings
                    parts = [part for part in parts if part]
                    if parts:
                        animal = parts[-1].strip()
                        animals.append(animal)
        return animals
    except Exception as e:
        safe_print(f"Error reading file: {e}")
        return []

def load_existing_results(output_file):
    """Load existing results from the output file to avoid redundant searches."""
    existing_results = {}
    try:
        if os.path.exists(output_file):
            with open(output_file, 'r', encoding='utf-8') as file:
                content = file.read()
                # Split by double newline to get each animal entry
                entries = content.split('\n\n')
                for entry in entries:
                    entry = entry.strip()
                    if entry and ': ' in entry:
                        # Extract animal name and description
                        parts = entry.split(': ', 1)
                        animal = parts[0].strip()
                        description = parts[1].strip()
                        existing_results[animal] = description
                        processed_animals.add(animal)
    except Exception as e:
        safe_print(f"Error loading existing results: {e}")
    
    return existing_results

def search_animal_description(animal_name):
    """Search for animal description using DuckDuckGo API."""
    # Use a rotating set of user agents to appear more like a regular browser
    user_agents = [
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Safari/605.1.15',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0',
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.107 Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.131 Safari/537.36 Edg/92.0.902.67'
    ]
    
    headers = {
        'User-Agent': user_agents[randint(0, len(user_agents) - 1)]
    }
    
    # Try DuckDuckGo API first (more friendly to scraping)
    try:
        # Construct a more specific search query
        query = f"{animal_name} species description habitat"
        url = f"https://api.duckduckgo.com/?q={query}&format=json"
        response = requests.get(url, headers=headers)
        
        if response.status_code == 200:
            data = response.json()
            
            # Check for an abstract (summary)
            if data.get('Abstract'):
                text = data['Abstract']
                sentences = re.split(r'[.!?]+', text)
                cleaned_sentences = [s.strip() for s in sentences if s.strip()]
                
                if len(cleaned_sentences) >= 2:
                    return '. '.join(cleaned_sentences[:3]) + '.'
                elif len(cleaned_sentences) >= 1:
                    return cleaned_sentences[0] + '.'
            
            # If no abstract, try related topics
            if data.get('RelatedTopics'):
                for topic in data['RelatedTopics']:
                    if 'Text' in topic:
                        text = topic['Text']
                        sentences = re.split(r'[.!?]+', text)
                        cleaned_sentences = [s.strip() for s in sentences if s.strip()]
                        if cleaned_sentences:
                            return '. '.join(cleaned_sentences[:min(3, len(cleaned_sentences))]) + '.'
                        
        # If DuckDuckGo fails, try Wikipedia API as a backup
        wiki_url = f"https://en.wikipedia.org/api/rest_v1/page/summary/{animal_name.replace(' ', '_')}"
        wiki_response = requests.get(wiki_url, headers=headers)
        
        if wiki_response.status_code == 200:
            wiki_data = wiki_response.json()
            if 'extract' in wiki_data:
                text = wiki_data['extract']
                sentences = re.split(r'[.!?]+', text)
                cleaned_sentences = [s.strip() for s in sentences if s.strip()]
                if len(cleaned_sentences) >= 2:
                    return '. '.join(cleaned_sentences[:3]) + '.'
                elif len(cleaned_sentences) >= 1:
                    return cleaned_sentences[0] + '.'
                
        safe_print(f"Debug - No results found for {animal_name}.")
        return "No description found."
    except Exception as e:
        safe_print(f"Error searching for description of {animal_name}: {e}")
        return f"Error: {str(e)}"

def save_result(animal, description, output_file):
    """Save a single result to the output file."""
    try:
        with file_lock:
            with open(output_file, 'a', encoding='utf-8') as file:
                file.write(f"{animal}: {description}\n\n")
    except Exception as e:
        safe_print(f"Error saving result for {animal}: {e}")

def worker(animal, output_file, progress_queue):
    """Worker thread function that searches for an animal description and saves it."""
    try:
        # Skip if already processed
        if animal in processed_animals:
            progress_queue.put(1)  # Increment progress counter
            return
        
        description = search_animal_description(animal)
        
        # Update the results dictionary
        with file_lock:
            results_dict[animal] = description
        
        # Save this result immediately
        save_result(animal, description, output_file)
        
        # Mark as processed
        processed_animals.add(animal)
        
        # Report progress
        safe_print(f"✓ {animal}: {description[:50]}..." if len(description) > 50 else f"✓ {animal}: {description}")
    except Exception as e:
        safe_print(f"Error in worker thread for {animal}: {e}")
        traceback.print_exc()
    finally:
        # Increment progress counter
        progress_queue.put(1)

def progress_reporter(total, progress_queue):
    """Thread that reports progress periodically."""
    completed = 0
    start_time = time.time()
    while completed < total:
        try:
            # Get the number of completed tasks
            increment = progress_queue.get(timeout=1)
            completed += increment
            
            # Calculate progress and ETA
            elapsed = time.time() - start_time
            progress = (completed / total) * 100
            
            if completed > 0 and elapsed > 0:
                items_per_second = completed / elapsed
                eta_seconds = (total - completed) / items_per_second if items_per_second > 0 else 0
                
                # Format ETA
                eta_minutes = int(eta_seconds // 60)
                eta_seconds = int(eta_seconds % 60)
                
                safe_print(f"Progress: {completed}/{total} ({progress:.1f}%) - ETA: {eta_minutes}m {eta_seconds}s")
        except queue.Empty:
            continue

def main():
    # Get the directory of the current script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Set the input file path
    file_path = "C:\\!Documents2\\Github\\School\\Bath-Hack-25\\lib\\database\\taxonomy_release.txt"
    
    # Set the output file path to be in the same directory as the script
    output_file = os.path.join(script_dir, "animal_descriptions.txt")
    
    # Check if file exists
    if not os.path.exists(file_path):
        safe_print(f"File not found: {file_path}")
        file_path = input("Please enter the correct file path: ")
    
    # Load existing results to avoid redundant searches
    existing_results = load_existing_results(output_file)
    safe_print(f"Loaded {len(existing_results)} existing results.")
    
    # Make sure the output file exists
    if not os.path.exists(output_file):
        with open(output_file, 'w', encoding='utf-8') as f:
            pass
    
    animals = read_animal_file(file_path)
    
    if not animals:
        safe_print("No animal names found in the file.")
        return
    
    # Filter out animals that already have results
    animals_to_process = [animal for animal in animals if animal not in processed_animals]
    
    safe_print(f"Found {len(animals)} animal(s) in the file.")
    safe_print(f"Need to process {len(animals_to_process)} animal(s).")
    
    if not animals_to_process:
        safe_print("All animals have already been processed!")
        return
    
    # Progress tracking queue
    progress_queue = queue.Queue()
    
    # Start the progress reporter thread
    progress_thread = threading.Thread(
        target=progress_reporter, 
        args=(len(animals_to_process), progress_queue)
    )
    progress_thread.daemon = True
    progress_thread.start()
    
    # Determine the number of threads to use (adjust this based on your system capabilities)
    # Usually 2-4x the number of CPU cores is a good starting point for I/O bound tasks
    max_workers = min(128, os.cpu_count() * 4)
    safe_print(f"Starting search with {max_workers} worker threads...")
    
    # Use ThreadPoolExecutor for managing threads
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        # Submit tasks for each animal
        futures = [
            executor.submit(worker, animal, output_file, progress_queue)
            for animal in animals_to_process
        ]
    
    safe_print("All searches completed!")
    safe_print(f"Results saved to {output_file}")

if __name__ == "__main__":
    main()