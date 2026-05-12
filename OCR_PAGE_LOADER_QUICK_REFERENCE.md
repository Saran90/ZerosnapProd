# OCR Page Loader - Quick Reference

## What Changed
✅ Page loader now shows when OCR API is being called
✅ Displays "Extracting passport details..." message
✅ Prevents user interaction during extraction
✅ Disappears when extraction completes

## Loader Design

### Visual Elements
- **Overlay**: Semi-transparent dark background (30% opacity)
- **Spinner**: Circular progress indicator (primary color)
- **Text**: "Extracting passport details..." (white, 16pt)

### Layout
```
┌─────────────────────────────────────┐
│                                     │
│    ◯ (loading spinner)              │
│                                     │
│  Extracting passport details...     │
│                                     │
└─────────────────────────────────────┘
```

## Implementation

### Added State Variable
```dart
bool _isExtractingOcr = false;
```

### Updated Extraction Method
```dart
setState(() => _isExtractingOcr = true);  // Show loader
try {
  // ... extraction logic ...
} finally {
  setState(() => _isExtractingOcr = false);  // Hide loader
}
```

### Updated Build Method
```dart
body: Stack(
  children: [
    // Form content
    SingleChildScrollView(...),
    
    // Loader overlay
    if (_isExtractingOcr)
      Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(...),
              SizedBox(height: 16),
              Text('Extracting passport details...'),
            ],
          ),
        ),
      ),
  ],
),
```

## User Experience

### Before
```
Capture image → Extraction starts → No feedback → Details appear
```

### After
```
Capture image → Extraction starts → ✅ Loader appears → Details appear → ✅ Loader disappears
```

## Affected Flows
- ✅ Camera capture flow
- ✅ Gallery upload flow
- ✅ Pre-selected image flow

## Testing

### Quick Test
1. Open passport details page
2. Capture/upload passport image
3. ✅ Verify loader appears
4. ✅ Verify "Extracting passport details..." message shows
5. ✅ Verify loader disappears when extraction completes

## Customization

### Change Text
```dart
const Text('Extracting passport details...')  // ← Change this
```

### Change Overlay Opacity
```dart
color: Colors.black.withValues(alpha: 0.3)  // ← Change 0.3
```

### Change Spinner Color
```dart
valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)  // ← Change color
```

## Status
✅ **Implementation Complete**
✅ **No Compilation Errors**
✅ **Ready for Testing**
