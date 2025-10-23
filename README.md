
# WooWop 🎵

A social music discovery app that allows users to identify songs using Shazam and request them to a DJ in real-time using peer-to-peer networking.

## Overview

WooWop enables seamless music discovery and sharing in social settings without requiring any backend infrastructure. Users can either become a DJ (host) to receive song requests, or join as a Listener to identify and request songs to the DJ.

### Key Features

- 🎵 **Song Recognition**: Powered by Apple's ShazamKit for accurate music identification
- 📡 **Peer-to-Peer Networking**: No backend required - uses MultipeerConnectivity framework
- 🎧 **Dual Roles**: DJ mode for receiving requests, Listener mode for sending requests
- ⚡ **Real-time Updates**: Song requests appear instantly across connected devices
- 🖼️ **Rich Metadata**: Displays song artwork, title, artist, and requester information

## Architecture

WooWop follows **Clean Architecture** principles with clear separation of concerns and modular design.

```
WooWop/
├── WooWopApp.swift                    # Main app entry point
├── ArtworkFeature/                    # Feature module (UI + Domain)
│   ├── Core/                          # Business logic layer
│   │   ├── MediaLoader.swift          # Protocol for song identification
│   │   └── MultipeerManager.swift     # P2P connectivity management
│   ├── Model/                         # Internal models
│   │   └── MediaItem.swift            # Observable class for UI binding
│   ├── MediaItem.swift                # Public domain models + DTOs
│   └── View/                          # User interface layer
│       ├── MainViews/                 # Primary screens
│       │   ├── ContentView.swift      # Main song discovery interface
│       │   ├── ConnectionSetupView.swift # Role selection & setup
│       │   ├── DJQueueView.swift      # DJ request management
│       │   └── SongRequestView.swift  # Song request submission
│       └── Subviews/                  # Reusable components
│           ├── AnimatedButton.swift
│           └── StarRating.swift
├── Artwork API/                       # External service integration
│   ├── ShazamClient.swift             # Protocol for Shazam integration
│   ├── SHManagedSessionClient.swift   # Concrete Shazam implementation
│   ├── RemoteMediaLoader.swift        # Service orchestration
│   ├── RemoteMediaMapper.swift        # Data transformation utilities
│   └── RemoteMediaItem.swift          # Internal API data structures
└── WooWopTests/                       # Test suite
    ├── WooWopTests.swift
    └── RemoteMediaLoaderTests.swift
```

## Key Architectural Decisions

### 1. Modular Separation

The codebase is organized into distinct modules with clear boundaries:

- **ArtworkFeature/**: Contains the core feature logic, UI, and domain models
- **Artwork API/**: Handles external Shazam service integration
- **Tests/**: Comprehensive test coverage for business logic

### 2. Protocol-Oriented Design

Key abstractions are defined through protocols:
- `MediaLoader`: Abstracts song identification logic
- `ShazamClient`: Abstracts Shazam API integration

This enables:
- Easy testing with mock implementations
- Flexibility to swap implementations
- Clear contract definitions between layers

### 3. Dependency Injection

Services are injected rather than directly instantiated, following the Dependency Inversion Principle:

```swift
ContentView(mediaLoader: RemoteMediaLoader(client: SHManagedSessionClient()))
```

## Important Design Patterns

### ⚠️ Intentional Model Duplication

**Before you "fix" this, read carefully!**

You'll notice `MediaItem` appears in two locations:

```
/ArtworkFeature/MediaItem.swift        # Public domain models + DTOs
/ArtworkFeature/Model/MediaItem.swift  # Internal Observable class
```

**This is intentional and follows Clean Architecture principles:**

#### Why We Have Two MediaItem Models

1. **`/ArtworkFeature/MediaItem.swift`**:
   - **Purpose**: Public domain model and data transfer objects
   - **Usage**: API boundaries, data exchange between modules
   - **Type**: `struct` (value semantics, immutable)
   - **Contains**: `MediaItem` and `SongRequest` structures

2. **`/ArtworkFeature/Model/MediaItem.swift`**:
   - **Purpose**: Internal UI state management
   - **Usage**: SwiftUI data binding and observation
   - **Type**: `@Observable class` (reference semantics, mutable)
   - **Contains**: Observable properties for UI updates

#### Benefits of This Approach

- **Separation of Concerns**: UI models don't leak into business logic
- **Anti-Corruption Layer**: External API changes don't affect internal models
- **Testability**: Can mock different model types independently
- **Flexibility**: UI and domain models can evolve separately
- **Type Safety**: Value types for data transfer, reference types for UI state

### Data Flow Architecture

```
Shazam API → RemoteMediaItem → MediaItem (struct) → UI
                                    ↓
                               Observable MediaItem (class) → SwiftUI Views
```

## Getting Started

### Prerequisites

- iOS 15.0+
- Xcode 14.0+
- Swift 5.5+

### Installation

1. Clone the repository
2. Open `WooWop.xcodeproj` in Xcode
3. Build and run on device or simulator

### Usage

1. **Launch the app** - You'll see the connection setup screen
2. **Choose your role**:
   - **"Become DJ"**: Host a session to receive song requests
   - **"Join as Listener"**: Connect to a DJ to send song requests
3. **Identify songs**: Tap the music note icon to use Shazam
4. **Request songs**: After identifying a song, tap the paper plane icon
5. **Manage requests**: DJs can view and manage requests in the queue view

## Testing

Run tests using:
```bash
⌘ + U in Xcode
# or
xcodebuild test -scheme WooWop
```

## Key Components

### MultipeerManager
Handles all peer-to-peer connectivity:
- Device discovery and connection
- Message transmission (song requests)
- Session management (DJ/Listener modes)

### MediaLoader
Orchestrates song identification:
- Audio capture and processing
- Shazam API integration
- Result transformation and error handling

### View Architecture
SwiftUI-based reactive UI:
- `ContentView`: Main interface with song display and controls
- `ConnectionSetupView`: Initial role selection and setup
- `DJQueueView`: Real-time request management for DJs
- `SongRequestView`: Song request submission interface

## Common Gotchas

### 1. Model Confusion
Don't merge the MediaItem models! They serve different purposes in the architecture.

### 2. Async/Await Usage
Song identification is asynchronous - always handle in proper contexts:
```swift
Task {
    try await getMediaItem()
}
```

### 3. MultipeerConnectivity Permissions
The app requires local network permissions for peer discovery.

### 4. Shazam Integration
Requires actual audio input - won't work with silent audio or simulator limitations.

## Contributing

1. Follow the existing architectural patterns
2. Add tests for new business logic
3. Document public APIs with Swift documentation comments
4. Respect module boundaries and separation of concerns

## License

[Add your license information here]

---

**Architecture Diagram**: https://app.excalidraw.com/s/429LLgVZqYi/6stRHymUCiq
