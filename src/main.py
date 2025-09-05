#!/usr/bin/env python3
"""
Main entry point for the Doubt Clearing AI application.
"""

import argparse
import sys
import logging
from typing import Optional

from core.processor import DoubtProcessor
from utils.helpers import setup_logging, load_config


def create_argument_parser() -> argparse.ArgumentParser:
    """Create and configure argument parser."""
    parser = argparse.ArgumentParser(
        description="Doubt Clearing AI - Clear your doubts effortlessly"
    )

    parser.add_argument(
        "--config",
        type=str,
        default="config/config.json",
        help="Path to configuration file",
    )

    parser.add_argument(
        "--verbose", "-v", action="store_true", help="Enable verbose logging"
    )

    parser.add_argument(
        "--interactive", "-i", action="store_true", help="Run in interactive mode"
    )

    parser.add_argument(
        "--question", "-q", type=str, help="Ask a single question and exit"
    )

    return parser


def interactive_mode(processor: DoubtProcessor) -> None:
    """Run the application in interactive mode."""
    print("🤖 Doubt Clearing AI - Ready to help!")
    print("Type 'quit', 'exit', or 'bye' to end the session.")
    print("-" * 50)

    while True:
        try:
            question = input("\n💭 Your doubt: ").strip()

            if question.lower() in ["quit", "exit", "bye", "q"]:
                print("\n👋 Goodbye! Happy learning!")
                break

            if not question:
                print("Please enter a question or type 'quit' to exit.")
                continue

            print("\n🔍 Processing your doubt...")
            response = processor.process_doubt(question)
            print(f"\n✨ Answer:\n{response}")

        except KeyboardInterrupt:
            print("\n\n👋 Goodbye! Happy learning!")
            break
        except Exception as e:
            logging.error(f"Error processing question: {e}")
            print(f"\n❌ Sorry, I encountered an error: {e}")


def single_question_mode(processor: DoubtProcessor, question: str) -> None:
    """Process a single question and exit."""
    try:
        print(f"🔍 Processing: {question}")
        response = processor.process_doubt(question)
        print(f"\n✨ Answer:\n{response}")
    except Exception as e:
        logging.error(f"Error processing question: {e}")
        print(f"❌ Error: {e}")
        sys.exit(1)


def main(config_path: Optional[str] = None) -> None:
    """Main application function."""
    parser = create_argument_parser()
    args = parser.parse_args()

    # Setup logging
    log_level = logging.DEBUG if args.verbose else logging.INFO
    setup_logging(level=log_level)

    try:
        # Load configuration
        config_file = config_path or args.config
        config = load_config(config_file)

        # Initialize processor
        processor = DoubtProcessor(config)

        # Run based on mode
        if args.question:
            single_question_mode(processor, args.question)
        elif args.interactive:
            interactive_mode(processor)
        else:
            # Default to interactive mode
            interactive_mode(processor)

    except Exception as e:
        logging.error(f"Failed to start application: {e}")
        print(f"❌ Failed to start: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
