.PHONY: build run format lint clean

# Build the project
build:
	swift build

# Run the app
run:
	swift run

# Format all Swift files
format:
	swiftformat Sources/ --swiftversion 5.9

# Check formatting without modifying (CI-friendly)
lint:
	swiftformat Sources/ --lint --swiftversion 5.9

# Clean build artifacts
clean:
	rm -rf .build
	rm -rf MouseJiggler.app/Contents/MacOS/MouseJiggler

# Build release version
release:
	swift build -c release
	mkdir -p MouseJiggler.app/Contents/MacOS
	cp .build/release/MouseJiggler MouseJiggler.app/Contents/MacOS/

# Install git hooks
install-hooks:
	chmod +x .git/hooks/pre-commit
	echo "Git hooks installed!"
