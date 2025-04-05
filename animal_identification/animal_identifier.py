#!/usr/bin/env python3
"""
Animal Identifier using SpeciesNet

This script runs the SpeciesNet classifier to identify wildlife in camera trap images.
"""

import os
import sys
from pathlib import Path


def check_dependencies():
    """Check if speciesnet package is installed."""
    try:
        import speciesnet
        print(f"Found speciesnet package")
        return True
    except ImportError:
        print("\nERROR: The 'speciesnet' package is not installed.")
        print("Please install it using: pip install speciesnet")
        return False


def run_speciesnet():
    """Run the SpeciesNet model with parameters from command line."""
    # Check for required packages
    if not check_dependencies():
        sys.exit(1)
    
    # Import the run_model module
    from speciesnet.scripts import run_model
    
    # Get the command line arguments (excluding the script name)
    argv = sys.argv[1:]
    
    print(f"\nRunning SpeciesNet with arguments: {' '.join(argv)}")
    
    # Run the model with the arguments
    try:
        run_model.main(argv)
        print("\nProcessing complete!")
    except Exception as e:
        print(f"\nError running SpeciesNet: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    run_speciesnet()