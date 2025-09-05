# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Development Commands

### Environment Setup
```bash
# Create and activate virtual environment
python -m venv venv
venv\Scripts\activate  # Windows
# source venv/bin/activate  # Linux/macOS

# Install dependencies
pip install -r requirements.txt

# Install development dependencies
pip install -e .[dev]
```

### Running the Application
```bash
# Interactive mode (default)
python src/main.py
python src/main.py --interactive

# Single question mode
python src/main.py --question "How does machine learning work?"

# With custom config file
python src/main.py --config path/to/config.json

# Verbose logging
python src/main.py --verbose

# Using as installed console script
doubt-clearing-ai
```

### Testing and Code Quality
```bash
# Run tests
python -m pytest tests/

# Run tests with coverage
python -m pytest tests/ --cov=src --cov-report=html

# Code formatting with Black
black src/

# Linting with flake8
flake8 src/

# Type checking with mypy
mypy src/
```

### Development Utilities
```bash
# Install package in development mode
pip install -e .

# Generate documentation
sphinx-build -b html docs/ docs/_build/

# Build package
python setup.py sdist bdist_wheel
```

## Architecture Overview

### Core Components

The Doubt Clearing AI follows a modular architecture with three main processing layers:

1. **DoubtProcessor** (`src/core/processor.py`)
   - Main orchestrator that handles question processing workflow
   - Manages conversation history and context
   - Coordinates between knowledge retrieval and explanation generation
   - Handles question analysis including type classification, domain identification, and complexity assessment

2. **KnowledgeBase** (`src/core/knowledge.py`)
   - Manages knowledge storage and retrieval
   - Implements simple keyword-based search with scoring
   - Organizes knowledge by domain with relevance ranking
   - Currently uses in-memory storage with basic knowledge items

3. **Explainer** (`src/core/explainer.py`)
   - Generates explanations tailored to user experience levels (beginner/intermediate/advanced)
   - Creates structured explanations with examples and analogies
   - Handles different question types (definition, procedure, explanation, etc.)
   - Formats responses with appropriate complexity and length

### Key Architectural Patterns

- **Configuration-driven**: All components accept configuration dictionaries for customization
- **Context-aware processing**: Uses `DoubtContext` dataclass to maintain conversation state
- **Layered approach**: Clear separation between question analysis, knowledge retrieval, and explanation generation
- **Fallback mechanisms**: Each component has error handling with meaningful fallback responses

### Data Flow

1. Question received by `DoubtProcessor.process_doubt()`
2. Question analyzed for type, domain, complexity, and intent
3. `KnowledgeBase.search()` retrieves relevant knowledge items
4. `Explainer.generate_explanation()` creates tailored response
5. Response formatted and returned with conversation history updated

## Project-Specific Development Guidelines

### Configuration Management
- The system uses JSON configuration in `config/config.json`
- Default configuration is auto-generated if missing via `utils.helpers.create_default_config()`
- Configuration validation ensures required sections and proper types
- Key configurable aspects: knowledge search parameters, explanation styles, logging levels

### Knowledge Base Extension
When adding new knowledge items:
- Use the `KnowledgeItem` dataclass structure
- Ensure proper domain classification for search efficiency
- Include relevant keywords for matching
- Consider confidence scores for ranking

### Question Processing Customization
The processor categorizes questions into types:
- `definition` - "What is..." questions
- `procedure` - "How to..." questions  
- `explanation` - "Why..." questions
- `temporal` - "When..." questions
- `location` - "Where..." questions
- `identification` - "Which/Who..." questions

### User Experience Levels
The explainer supports three user levels:
- **Beginner**: Simple language, examples, analogies, max 300 chars
- **Intermediate**: Moderate complexity, examples, no analogies, max 500 chars  
- **Advanced**: Detailed explanations, no examples/analogies, max 800 chars

### Error Handling Philosophy
- Graceful degradation: Components provide fallback responses rather than failing
- Detailed logging at appropriate levels
- User-friendly error messages that maintain the conversational tone
- Configuration issues auto-resolve with defaults where possible

### Entry Points and Interfaces
- **CLI Interface**: `src/main.py` with argument parsing for interactive/single-question modes
- **Python Module**: Import `DoubtProcessor` directly for programmatic use
- **Console Script**: `doubt-clearing-ai` command available after installation
- **API Interface**: Mentioned in documentation but not yet implemented

### Dependencies and Tech Stack
- **Core AI**: OpenAI, Transformers, PyTorch for AI capabilities
- **Web Framework**: Flask and FastAPI for future API development
- **NLP Libraries**: NLTK, spaCy for natural language processing
- **Testing**: pytest with coverage and async support
- **Code Quality**: black, flake8, mypy for formatting and type checking
- **Documentation**: Sphinx and MkDocs for documentation generation

### Development Workflow Considerations
- The codebase follows PEP 8 style guidelines
- Virtual environment usage is expected for dependency isolation
- Configuration files should not contain sensitive information
- The system is designed to be extended with external knowledge sources
- Conversation history is maintained in-memory (consider persistence for production)
