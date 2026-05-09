# FRRO Feature Architecture

## 📐 Clean Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                       │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  FrroListPage (UI)                                     │ │
│  │  - WebView for FRRO form                              │ │
│  │  - Guest list bottom sheet                            │ │
│  │  - Loading & error states                             │ │
│  └────────────────────────────────────────────────────────┘ │
│                           ↕                                  │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  GuestListBloc (State Management)                      │ │
│  │  - LoadGuestList event                                │ │
│  │  - RefreshGuestList event                             │ │
│  │  - GuestListLoading state                             │ │
│  │  - GuestListLoaded state                              │ │
│  │  - GuestListError state                               │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                           ↕
┌─────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                            │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  GetGuestList (Use Case)                               │ │
│  │  - Business logic                                      │ │
│  │  - Calls repository                                    │ │
│  └────────────────────────────────────────────────────────┘ │
│                           ↕                                  │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  GuestRepository (Interface)                           │ │
│  │  - getGuestList(branchId, userId, status)             │ │
│  └────────────────────────────────────────────────────────┘ │
│                           ↕                                  │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Guest (Entity)                                        │ │
│  │  - Pure business model                                 │ │
│  │  - No dependencies                                     │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                           ↕
┌─────────────────────────────────────────────────────────────┐
│                       DATA LAYER                             │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  GuestRepositoryImpl (Implementation)                  │ │
│  │  - Implements GuestRepository                          │ │
│  │  - Error handling                                      │ │
│  │  - Maps models to entities                             │ │
│  └────────────────────────────────────────────────────────┘ │
│                           ↕                                  │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  GuestRemoteDataSource                                 │ │
│  │  - API communication                                   │ │
│  │  - HTTP requests                                       │ │
│  └────────────────────────────────────────────────────────┘ │
│                           ↕                                  │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  GuestModel (DTO)                                      │ │
│  │  - JSON serialization                                  │ │
│  │  - fromJson / toJson                                   │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                           ↕
┌─────────────────────────────────────────────────────────────┐
│                      EXTERNAL                                │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  ApiBaseHelper (HTTP Client)                           │ │
│  │  - POST /api/GuestDataForChrome                        │ │
│  └────────────────────────────────────────────────────────┘ │
│                           ↕                                  │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Smart Check-in API                                    │ │
│  │  http://smartcheckindev.atintellilabs.live             │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow

### Loading Guests
```
User Action (Open Page)
    ↓
LoadGuestList Event
    ↓
GuestListBloc
    ↓
GetGuestList UseCase
    ↓
GuestRepository.getGuestList()
    ↓
GuestRepositoryImpl
    ↓
GuestRemoteDataSource.getGuestList()
    ↓
ApiBaseHelper.post()
    ↓
HTTP POST Request
    ↓
Smart Check-in API
    ↓
JSON Response
    ↓
List<GuestModel>
    ↓
List<Guest> (Entity)
    ↓
Right(List<Guest>)
    ↓
GuestListLoaded State
    ↓
UI Update (Display Guests)
```

### Error Flow
```
HTTP Request
    ↓
Network Error / Server Error
    ↓
Exception Caught
    ↓
Left(Failure)
    ↓
GuestListError State
    ↓
UI Update (Show Error Message)
```

## 🎯 Dependency Injection

```
┌─────────────────────────────────────────┐
│     Injection Container (GetIt)         │
├─────────────────────────────────────────┤
│                                         │
│  ApiBaseHelper (Singleton)              │
│         ↓                               │
│  GuestRemoteDataSource (Lazy Singleton) │
│         ↓                               │
│  GuestRepository (Lazy Singleton)       │
│         ↓                               │
│  GetGuestList (Lazy Singleton)          │
│         ↓                               │
│  GuestListBloc (Factory)                │
│                                         │
└─────────────────────────────────────────┘
```

## 📦 Module Structure

```
lib/features/frro/
│
├── domain/                    # Business Logic Layer
│   ├── entities/
│   │   └── guest.dart        # Pure business model
│   ├── repositories/
│   │   └── guest_repository.dart  # Repository contract
│   └── usecases/
│       └── get_guest_list.dart    # Business use case
│
├── data/                      # Data Layer
│   ├── models/
│   │   └── guest_model.dart  # Data transfer object
│   ├── datasources/
│   │   └── guest_remote_data_source.dart  # API client
│   └── repositories/
│       └── guest_repository_impl.dart     # Repository implementation
│
├── presentation/              # UI Layer
│   ├── bloc/
│   │   ├── guest_list_bloc.dart   # State management
│   │   ├── guest_list_event.dart  # Events
│   │   └── guest_list_state.dart  # States
│   ├── pages/
│   │   └── frro_list_page.dart    # Main UI
│   └── widgets/
│       └── guest_filter_dialog.dart  # Filter widget
│
└── README.md                  # Documentation
```

## 🔐 Error Handling Strategy

```
┌─────────────────────────────────────────┐
│         Exception Types                 │
├─────────────────────────────────────────┤
│                                         │
│  NetworkException                       │
│    → NetworkFailure                     │
│    → "No internet connection"           │
│                                         │
│  ServerException                        │
│    → ServerFailure                      │
│    → "Server error occurred"            │
│                                         │
│  FormatException                        │
│    → ServerFailure                      │
│    → "Invalid response format"          │
│                                         │
└─────────────────────────────────────────┘
```

## 🎨 State Management Flow

```
┌──────────────────────────────────────────────────┐
│              GuestListBloc States                │
├──────────────────────────────────────────────────┤
│                                                  │
│  GuestListInitial                                │
│    ↓ (LoadGuestList event)                      │
│  GuestListLoading                                │
│    ↓ (Success)          ↓ (Failure)             │
│  GuestListLoaded    GuestListError               │
│    ↓ (RefreshGuestList event)                   │
│  GuestListLoading                                │
│    ↓ (Success)          ↓ (Failure)             │
│  GuestListLoaded    GuestListError               │
│                                                  │
└──────────────────────────────────────────────────┘
```

## 🧪 Testing Strategy

### Unit Tests
- ✅ Test use cases in isolation
- ✅ Test repository implementation
- ✅ Test data source
- ✅ Test model serialization

### Widget Tests
- ✅ Test UI components
- ✅ Test BLoC integration
- ✅ Test user interactions

### Integration Tests
- ✅ Test complete feature flow
- ✅ Test API integration
- ✅ Test error scenarios

## 🚀 Performance Considerations

1. **Lazy Loading**: Dependencies loaded only when needed
2. **Factory Pattern**: New BLoC instance per page
3. **Efficient Serialization**: Direct JSON mapping
4. **Error Recovery**: Graceful error handling
5. **State Preservation**: BLoC maintains state during navigation

## 🔄 Future Enhancements

1. **Caching Layer**: Add local data source
2. **Offline Support**: Store data locally
3. **Pagination**: Load guests in batches
4. **Real-time Updates**: WebSocket integration
5. **Search & Filter**: Advanced filtering options
