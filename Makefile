# Ad-hoc by default; override for a rebuild-stable signature:
#   make app CODESIGN_IDENTITY="MoveWindows Dev"
CODESIGN_IDENTITY ?= -

# With Command Line Tools only (no Xcode), Testing.framework and its dylib
# live outside the default search paths.
CLT_FRAMEWORKS := /Library/Developer/CommandLineTools/Library/Developer/Frameworks
CLT_LIBS := /Library/Developer/CommandLineTools/Library/Developer/usr/lib
TEST_FLAGS := -Xswiftc -F -Xswiftc $(CLT_FRAMEWORKS) \
              -Xlinker -F -Xlinker $(CLT_FRAMEWORKS) \
              -Xlinker -rpath -Xlinker $(CLT_FRAMEWORKS) \
              -Xlinker -rpath -Xlinker $(CLT_LIBS)

.PHONY: build test run app install clean

build:
	swift build

test:
	swift test $(TEST_FLAGS)

# Dev loop: unbundled binary; TCC attributes Accessibility to your terminal,
# so grant the terminal once and every rebuild inherits it.
run:
	swift run

app:
	scripts/build-app.sh "$(CODESIGN_IDENTITY)"

install: app
	rm -rf /Applications/MoveWindows.app
	ditto build/MoveWindows.app /Applications/MoveWindows.app
	@echo "Installed to /Applications/MoveWindows.app"

clean:
	swift package clean
	rm -rf build
