from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

with open("requirements.txt", "r", encoding="utf-8") as fh:
    requirements = [line.strip() for line in fh if line.strip() and not line.startswith("#")]

setup(
    name="doubt-clearing-ai",
    version="0.1.0",
    author="Your Name",
    author_email="your.email@example.com",
    description="An intelligent AI assistant designed to clear your doubts effortlessly",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/yourusername/doubt-clearing-ai",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "Intended Audience :: Education",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
        "Topic :: Education",
        "Topic :: Software Development :: Libraries :: Python Modules",
    ],
    python_requires=">=3.8",
    install_requires=requirements,
    extras_require={
        "dev": [
            "pytest>=7.4.0",
            "pytest-cov>=4.1.0",
            "black>=23.0.0",
            "flake8>=6.0.0",
            "mypy>=1.5.0",
        ],
        "docs": [
            "sphinx>=7.0.0",
            "mkdocs>=1.5.0",
        ],
    },
    entry_points={
        "console_scripts": [
            "doubt-clearing-ai=src.main:main",
        ],
    },
    include_package_data=True,
    zip_safe=False,
)
