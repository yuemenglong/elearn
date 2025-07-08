# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter-based English learning application (elearn) that provides comprehensive language learning through speech recognition, AI-powered quizzes, and pronunciation practice. The app is built around New Concept English curriculum with bilingual (English/Chinese) support.

## Development Commands

### Running the Application
```bash
flutter run                    # Run on connected device/emulator
flutter run -d chrome         # Run in web browser
flutter run -d windows        # Run on Windows desktop
flutter run -d macos          # Run on macOS desktop
flutter run -d linux          # Run on Linux desktop
```

### Development Workflow
```bash
flutter analyze               # Static code analysis
flutter test                  # Run unit tests (if available)
flutter clean                 # Clean build artifacts
flutter pub get               # Get dependencies
flutter pub upgrade           # Upgrade dependencies
```

### Building
```bash
flutter build apk            # Build Android APK
flutter build appbundle      # Build Android App Bundle
flutter build ios            # Build iOS app
flutter build web            # Build web version
flutter build windows        # Build Windows desktop
flutter build macos          # Build macOS desktop
flutter build linux          # Build Linux desktop
```

## Architecture Overview

### Core Application Structure
- **Entry Point**: `lib/main.dart` - Initializes database, context, and routing
- **Database**: SQLite-based persistence layer in `lib/db/` with cross-platform support (sqflite_ffi for desktop)
- **Context Management**: `lib/context/context.dart` - Global app state and user account management
- **Routing**: MaterialApp with named routes for different learning modes

### Key Directories
- `lib/page/` - Main application screens (home, quiz, reading practice)
- `lib/util/pack/` - Core utilities for LLM integration, audio processing, and text analysis
- `lib/db/` - Database models and mappers for data persistence
- `lib/widget/` - Reusable UI components and dialogs
- `assets/NewConcept1/` - Lesson content (XML files for 49 lessons)

### Learning System Components

#### Quiz System
- **Standard Quizzes**: English↔Chinese translation with AI-generated multiple choice options
- **Reading Quiz**: Sentence-based comprehension with audio playback
- **Question Types**: Both vocabulary words and complete sentences
- **Caching**: SQLite-based caching of AI-generated quiz options for performance

#### Audio Processing
- **Text-to-Speech**: Alibaba Cloud NLS integration with MD5-based caching
- **Speech-to-Text**: Real-time pronunciation assessment using ASR
- **Audio Playback**: Cross-platform audio playback with completion handling

#### AI Integration
- **LLM Provider**: DeepSeek API for English tutoring assistance
- **Question Generation**: AI-powered multiple choice distractor creation
- **Pronunciation Evaluation**: LLM-based comparison of user speech vs. target text

### Database Schema
- `account` - User accounts and settings
- `favour_sentence` - User's favorite sentences for review
- `star` - Achievement tracking for perfect quiz scores  
- `quiz_cache` - Cached AI-generated quiz options
- `user_settings` - Application preferences per user

### External Service Dependencies
- **Alibaba Cloud NLS**: Text-to-speech and speech-to-text services
- **DeepSeek LLM**: AI tutoring and question generation
- **Authentication**: HMAC-SHA1 token-based authentication for cloud services

## Development Guidelines

### Data Loading Patterns
- Lessons loaded from XML files in assets with caching
- Database operations use async/await patterns consistently
- Error handling with retry mechanisms for external API calls

### UI Conventions
- Material Design with custom color scheme (`Const.backgroundColor`, `Const.lightColor`)
- Responsive layout using SizedBox and proper spacing
- Bilingual text display (English/Chinese) throughout interface

### Performance Considerations
- SQLite database initialization required before app start (`Db.init()`)
- Lesson content cached in memory after first load
- Audio files cached locally to avoid redundant API calls
- Quiz options pre-loaded and cached for smooth user experience

### Code Organization
- Database mappers follow consistent pattern with static methods
- Utility functions in `lib/util/pack/` use `do` prefix convention
- Widget classes follow Flutter naming conventions
- State management through StatefulWidget pattern

### Asset Management
- Lesson files in `assets/NewConcept1/` numbered 1-97
- File paths loaded from `assets/files.txt`
- Audio caching handled automatically by utility functions