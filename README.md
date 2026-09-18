# CS Price Scanner - Windows Desktop App

A Flutter-based barcode scanner application for Windows that looks up product prices directly from a MySQL database. This is a desktop port of the Android "CS Price Scanner" app.

## Features

- **Device Registration** — Generate device codes with a simple registration formula (÷2 + 8)
- **Barcode Scanning** — USB/Bluetooth barcode reader support via keyboard input, or manual entry
- **Real-time Price Lookup** — Query MySQL database for 5 price types:
  - Retail Price
  - Wholesale Price
  - Half Wholesale Price
  - Export Price
  - Consumer Price
  - Cost Price
- **Direct MySQL Connection** — No middleware required
- **License Validation** — Check license duration against database
- **Settings Management** — Configurable server IP, port, database name, and credentials

## Requirements

### System Requirements
- Windows 10 or Windows 11
- 200 MB disk space
- USB barcode reader (optional — manual entry supported)

### Development Requirements (to build from source)
- Flutter SDK 3.0+
- Visual Studio 2022 with "Desktop development with C++" workload
- Git

## Installation

### Option 1: Download Pre-built Executable
Download the latest `.exe` from the [Releases](../../releases) page and run it directly.

### Option 2: Build from Source

1. **Install Flutter**
   ```bash
   # Download Flutter SDK for Windows
   # Extract to C:\flutter
   # Add C:\flutter\bin to PATH
   
   flutter config --enable-windows-desktop
   flutter doctor
   ```

2. **Clone the repository**
   ```bash
   git clone https://github.com/kinzocash-commits/hpc-pricechecker-port.git
   cd hpc-pricechecker-port
   ```

3. **Get dependencies**
   ```bash
   flutter pub get
   ```

4. **Build the app**
   ```bash
   flutter build windows --release
   ```

5. **Run the built app**
   ```bash
   .\build\windows\x64\runner\Release\cs_price_scanner.exe
   ```

## Usage

### First Launch - Device Registration

1. The app displays a **Device Code** (6-digit number)
2. Calculate: `(Device Code ÷ 2) + 8`
3. Enter the result as the **Registration Code**
4. On first registration, you'll need to configure database settings:
   - **Server IP**: Your MySQL server address (e.g., `192.168.1.100`)
   - **Port**: MySQL port (default: `3306`)
   - **Database Name**: Name of your database
   - **Username**: MySQL username
   - **Password**: MySQL password

### Scanner Screen

1. **Focus the barcode input field** (automatically focused on startup)
2. **Scan a barcode** using a USB barcode reader, or type manually
3. Press **Enter** to look up the product
4. View pricing information for the scanned item
5. Scan the next barcode (field auto-clears and re-focuses)

### Settings Screen

- View current registration info (User ID, Device ID, License status)
- Update database connection settings
- Test connection to validate settings
- Monitor license validity period

## Database Schema

The app expects the following MySQL table structure:

```sql
-- Products table
CREATE TABLE tbl_item (
  it_id INT PRIMARY KEY,
  it_unit_id INT,
  it_id_currency INT,
  it_cost_per_unit DECIMAL(10, 2),
  it_unit_equal INT,
  it_un_price_sell_a DECIMAL(10, 2),     -- Retail Price
  it_un_price_sell_b DECIMAL(10, 2),     -- Wholesale Price
  it_un_price_sell_c DECIMAL(10, 2),     -- Half Wholesale
  it_un_price_sell_d DECIMAL(10, 2),     -- Export Price
  it_un_price_sell_e DECIMAL(10, 2)      -- Consumer Price
);

-- Barcode mapping
CREATE TABLE tbl_item_barcode (
  it_item_id INT,
  it_barcode_item_id INT,
  it_barcode_unit_id INT,
  it_barcode_value VARCHAR(255) PRIMARY KEY,
  FOREIGN KEY (it_item_id) REFERENCES tbl_item(it_id)
);

-- User registration (for device validation)
CREATE TABLE user_devices (
  device_id VARCHAR(255) PRIMARY KEY,
  user_id INT
);

-- License tracking
CREATE TABLE user_licenses (
  user_id INT PRIMARY KEY,
  expiry_date DATE
);

-- Stored function for cost calculation
CREATE FUNCTION func_get_item_cost2(
  p_item_id INT,
  p_unit_id INT,
  p_currency_id INT,
  p_cost DECIMAL(10, 2),
  p_unit_equal INT
) RETURNS DECIMAL(10, 2)
BEGIN
  -- Implementation based on your business logic
  RETURN p_cost;
END;
```

## Configuration

Settings are stored locally in Windows Registry (via `shared_preferences`):
- `serverIP` — MySQL server address
- `port` — MySQL port
- `dbName` — Database name
- `username` — MySQL username
- `password` — MySQL password
- `userId` — Registered user ID
- `deviceId` — Device identifier
- `isUserAdd` — User authorization flag

### Test Connection

Use the **"Test Connection"** button in Settings to validate:
- MySQL server connectivity
- Database access with provided credentials
- Query execution

## Barcode Reader Setup

### USB Barcode Readers
Most USB barcode readers work as **keyboard wedge devices** — they automatically send barcode data as keyboard input. No drivers needed.

1. Connect the barcode reader to a USB port
2. Click in the barcode input field
3. Scan a barcode — it will appear in the field automatically
4. Press Enter to look up

### Manual Entry
If no reader is available, type the barcode manually and press Enter.

## Architecture

- **Frontend**: Flutter with Material Design 3
- **Database**: MySQL direct connection via `mysql1` package
- **Storage**: Windows Registry (via `shared_preferences`)
- **Platform**: Windows Desktop (Flutter native)

### Key Dependencies
- `flutter` — UI framework
- `mysql1` — MySQL database driver
- `shared_preferences` — Local settings storage
- `device_info_plus` — Device identification
- `window_manager` — Window control
- `crypto` — Password hashing (future use)

## Development

### Project Structure
```
lib/
├── main.dart                    # App entry point
├── screens/
│   ├── registration_screen.dart # Device registration & DB settings
│   ├── scanner_screen.dart      # Barcode scanning & lookup
│   └── settings_screen.dart     # Settings & license info
└── services/
    ├── settings_service.dart    # Local storage abstraction
    └── database_service.dart    # MySQL operations
```

### Running in Debug Mode
```bash
flutter run -d windows
```

### Hot Reload
Press `r` during a debug session to hot-reload code changes.

## Troubleshooting

### "Database connection settings are incomplete"
- Go to Settings → Configure Database Settings
- Enter all required fields (Server IP, Port, DB Name, Username, Password)
- Click "Test Connection" to validate

### "Connection failed"
- Verify MySQL server is running and accessible
- Check firewall isn't blocking port 3306 (or your custom port)
- Confirm database name, username, and password are correct
- Try connecting from command line: `mysql -h <IP> -u <username> -p<password> -D <dbname>`

### "Device not authorized"
- The device hasn't been registered in your database
- Contact administrator to add this device to `user_devices` table
- Format: Calculate `(device_code ÷ 2) + 8` to get registration code

### "License expired"
- Check expiry date in `user_licenses` table
- Contact administrator to extend license

### Barcode not scanning
- Ensure the barcode input field is focused (click it first)
- Test barcode reader on another app (Notepad) to verify it works
- Some readers have a configuration mode — consult manual

## Building for Release

```bash
# Build release executable
flutter build windows --release

# Executable location
build/windows/x64/runner/Release/cs_price_scanner.exe

# Create installer (optional, requires NSIS)
flutter build windows --release
```

## Contributing

For bug reports or feature requests, please open an issue on GitHub.

## License

Proprietary — Contact CIT for licensing details.

## Support

For technical support, contact: support@cit.example.com

---

**Version**: 1.0.0  
**Last Updated**: September 2026  
**Platform**: Windows 10+  
**Built with**: Flutter 3.0+