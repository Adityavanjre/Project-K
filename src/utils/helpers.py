"""
Helper functions and utilities for the Doubt Clearing AI system.
"""

import json
import logging
import os
from typing import Dict, Any, Optional


def setup_logging(
    level: int = logging.INFO, format_string: Optional[str] = None
) -> None:
    """
    Set up logging configuration for the application.

    Args:
        level: Logging level (e.g., logging.INFO, logging.DEBUG)
        format_string: Custom format string for log messages
    """
    if format_string is None:
        format_string = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"

    logging.basicConfig(level=level, format=format_string, datefmt="%Y-%m-%d %H:%M:%S")

    # Set specific loggers to appropriate levels
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.getLogger("requests").setLevel(logging.WARNING)

    logger = logging.getLogger(__name__)
    logger.info(f"Logging configured with level: {logging.getLevelName(level)}")


def load_config(config_path: str) -> Dict[str, Any]:
    """
    Load configuration from a JSON file.

    Args:
        config_path: Path to the configuration file

    Returns:
        Configuration dictionary

    Raises:
        FileNotFoundError: If config file doesn't exist
        json.JSONDecodeError: If config file is not valid JSON
    """
    logger = logging.getLogger(__name__)

    # If config file doesn't exist, create a default one
    if not os.path.exists(config_path):
        logger.warning(
            f"Config file not found: {config_path}. Creating default configuration."
        )
        default_config = create_default_config()

        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(config_path), exist_ok=True)

        # Save default config
        with open(config_path, "w", encoding="utf-8") as f:
            json.dump(default_config, f, indent=2)

        logger.info(f"Default configuration saved to: {config_path}")
        return default_config

    try:
        with open(config_path, "r", encoding="utf-8") as f:
            config = json.load(f)

        logger.info(f"Configuration loaded from: {config_path}")
        return config

    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in config file {config_path}: {e}")
        raise
    except Exception as e:
        logger.error(f"Error loading config file {config_path}: {e}")
        raise


def create_default_config() -> Dict[str, Any]:
    """
    Create a default configuration dictionary.

    Returns:
        Default configuration dictionary
    """
    return {
        "application": {
            "name": "KALI",
            "version": "0.1.0",
            "debug": False,
        },
        "knowledge": {
            "max_search_results": 5,
            "confidence_threshold": 0.1,
            "enable_domain_filtering": True,
        },
        "explainer": {
            "default_user_level": "intermediate",
            "max_explanation_length": 500,
            "include_examples": True,
            "include_analogies": False,
        },
        "logging": {
            "level": "INFO",
            "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        },
        "api": {"host": "localhost", "port": 8000, "debug": False},
    }


def validate_config(config: Dict[str, Any]) -> bool:
    """
    Validate configuration dictionary for required fields and correct types.

    Args:
        config: Configuration dictionary to validate

    Returns:
        True if valid, False otherwise
    """
    logger = logging.getLogger(__name__)

    required_sections = ["application", "knowledge", "explainer", "logging"]

    for section in required_sections:
        if section not in config:
            logger.error(f"Missing required configuration section: {section}")
            return False

    # Validate specific fields
    try:
        # Application section
        app_config = config["application"]
        if not isinstance(app_config.get("name"), str):
            logger.error("application.name must be a string")
            return False

        # Knowledge section
        knowledge_config = config["knowledge"]
        if not isinstance(knowledge_config.get("max_search_results"), int):
            logger.error("knowledge.max_search_results must be an integer")
            return False

        # Explainer section
        explainer_config = config["explainer"]
        valid_levels = ["beginner", "intermediate", "advanced"]
        if explainer_config.get("default_user_level") not in valid_levels:
            logger.error(f"explainer.default_user_level must be one of: {valid_levels}")
            return False

        logger.info("Configuration validation successful")
        return True

    except Exception as e:
        logger.error(f"Error during configuration validation: {e}")
        return False


def get_project_root() -> str:
    """
    Get the project root directory path.

    Returns:
        Absolute path to the project root
    """
    # Get the directory containing this file
    current_dir = os.path.dirname(os.path.abspath(__file__))

    # Go up two levels: src/utils -> src -> project_root
    project_root = os.path.dirname(os.path.dirname(current_dir))

    return project_root


def ensure_directory(directory_path: str) -> bool:
    """
    Ensure that a directory exists, creating it if necessary.

    Args:
        directory_path: Path to the directory

    Returns:
        True if directory exists or was created successfully
    """
    logger = logging.getLogger(__name__)

    try:
        os.makedirs(directory_path, exist_ok=True)
        logger.debug(f"Directory ensured: {directory_path}")
        return True
    except Exception as e:
        logger.error(f"Failed to create directory {directory_path}: {e}")
        return False


def format_response(content: str, response_type: str = "text") -> Dict[str, Any]:
    """
    Format a response for consistent output.

    Args:
        content: The response content
        response_type: Type of response (text, error, success)

    Returns:
        Formatted response dictionary
    """
    import time

    return {
        "content": content,
        "type": response_type,
        "timestamp": time.time(),
        "status": "success" if response_type != "error" else "error",
    }
