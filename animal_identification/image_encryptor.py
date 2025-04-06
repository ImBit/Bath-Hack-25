import base64
import sys
import os
import argparse

def encode_image_to_base64(image_path):
    """
    Reads an image file and converts it to a Base64 encoded string.

    Args:
        image_path (str): Path to the image file

    Returns:
        str: Base64 encoded string
    """
    try:
        # Check if file exists
        if not os.path.isfile(image_path):
            print(f"Error: File '{image_path}' does not exist")
            return None

        # Read the image file as binary
        with open(image_path, 'rb') as image_file:
            # Encode the binary data to base64
            encoded_string = base64.b64encode(image_file.read())

            # Convert bytes to string for output
            return encoded_string.decode('utf-8')

    except Exception as e:
        print(f"Error encoding image: {e}")
        return None

def save_to_file(encoded_string, output_path):
    """
    Saves the encoded string to a file

    Args:
        encoded_string (str): Base64 encoded string
        output_path (str): Path to save the output file
    """
    try:
        with open(output_path, 'w') as output_file:
            output_file.write(encoded_string)
        print(f"Encoded string saved to {output_path}")
    except Exception as e:
        print(f"Error saving to file: {e}")

def main():
    # Create argument parser
    parser = argparse.ArgumentParser(description="Encode an image file to Base64 string for Flutter")
    parser.add_argument("image_path", help="Path to the image file to encode")
    parser.add_argument("-o", "--output", help="Output file path (optional)")
    parser.add_argument("-c", "--clipboard", action="store_true", help="Copy result to clipboard")

    # Parse arguments
    args = parser.parse_args()

    # Encode the image
    encoded_string = encode_image_to_base64(args.image_path)

    if encoded_string:
        # Print the first 100 characters of the encoded string
        preview = encoded_string[:100] + "..." if len(encoded_string) > 100 else encoded_string
        print(f"Encoded string (preview): {preview}")
        print(f"Total length: {len(encoded_string)} characters")

        # Save to file if output path is provided
        if args.output:
            save_to_file(encoded_string, args.output)

        # Copy to clipboard if requested
        if args.clipboard:
            try:
                import pyperclip
                pyperclip.copy(encoded_string)
                print("Encoded string copied to clipboard")
            except ImportError:
                print("pyperclip module not found. Install it with 'pip install pyperclip' to use clipboard functionality.")
            except Exception as e:
                print(f"Error copying to clipboard: {e}")

if __name__ == "__main__":
    main()