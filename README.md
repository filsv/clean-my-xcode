# Clean My Xcode

A powerful bash script to clean and manage Xcode cache directories interactively, helping you reclaim disk space and keep your development environment tidy.

## Features

- **Interactive Directory Selection**: Navigate through directories and subfolders to delete specific items.
- **Sort by Last Used Date**: Prioritize cache removal based on when directories were last accessed.
- **User-Friendly Warnings and Display**: Provides clear, detailed information with formatted tables and alerts before any action.
- **Quick Cleanup Options**: Easily remove all cache directories or selectively delete specific ones.

### Script Options

1. **Delete All Directories**: Removes all listed Xcode cache directories.
2. **Select Specific Directories**: Explore directories and delete specific subfolders or files interactively.

### Example Output

```bash
Found the following Xcode cache directories (sorted by last used date):
---------------------------------------------------------------
No.   Last Used           Size       Path
---------------------------------------------------------------
1     2025-01-28 15:00:00 19G        /Users/username/Library/Developer/Xcode/DerivedData
2     2025-01-25 12:30:00 9.0M       /Users/username/Library/Developer/Xcode/Archives
3     2025-01-22 10:20:00 219M       /Users/username/Library/Developer/Xcode/Products
---------------------------------------------------------------
Total size: ~19.2 GB
```

## Quick Start

Run the script directly using the following command:

### Using curl
```bash
curl -fsSL https://raw.githubusercontent.com/filsv/clean-my-xcode/main/clean-my-xcode.sh -o clean-my-xcode.sh && bash clean-my-xcode.sh
```

### Using bash
For an even quicker execution without downloading the file:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/filsv/clean-my-xcode/main/clean-my-xcode.sh)
```

### Enjoy cleaning your Xcode cache easily and efficiently! 🚀

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.
