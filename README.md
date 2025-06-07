# Secure Password Manager

A secure, cross-platform password manager built with Flutter.

## Features

- Secure password storage with AES-256 encryption
- Biometric authentication
- Cross-platform support (Web, Mobile, Desktop)
- Secure clipboard handling
- Auto-lock functionality
- Password strength analysis
- Secure data export/import

## Testing Locally

### Prerequisites

1. Install Flutter SDK
2. Install Python 3.x
3. Install Git

### Steps to Test

1. Clone the repository:
```bash
git clone https://github.com/yourusername/password-manager.git
cd password-manager
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the test script:
```bash
# On Windows
test_web.bat

# On Linux/Mac
chmod +x test_web.sh
./test_web.sh
```

4. Open your browser and navigate to:
```
http://localhost:8000
```

## Deployment

The app is automatically deployed to GitHub Pages when changes are pushed to the main branch.

### Manual Deployment

1. Build the web app:
```bash
flutter build web --release
```

2. The built files will be in the `build/web` directory

### Deployment URL

Once deployed, your app will be available at:
```
https://yourusername.github.io/password-manager
```

## Security Features

- AES-256 encryption for password storage
- PBKDF2 key derivation
- Secure session management
- Biometric authentication
- Auto-lock functionality
- Secure clipboard handling
- Input validation
- XSS protection
- CSRF protection

## Development

### Project Structure

```
lib/
  ├── config/         # Configuration files
  ├── services/       # Core services
  ├── screens/        # UI screens
  └── widgets/        # Reusable widgets
```

### Adding New Features

1. Create feature branch:
```bash
git checkout -b feature/new-feature
```

2. Make changes and test locally

3. Create pull request to main branch

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 