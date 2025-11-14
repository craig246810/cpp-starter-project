# 📘 C++ Project Template (with Static Library, Tests, Coverage & Colour Output)

This project is a clean, modern C++ starter template that demonstrates:

- A proper multi-file C++ project layout
- A static library (`libapp.a`) built from `src/lib/`
- A main application in `src/`
- A simple example math module
- Automatic test discovery and coloured test output
- Code coverage reporting (via `gcovr`)
- Debug/Release build modes
- Optional Linux API integration via `pkg-config`
- A feature-rich Makefile with sanity, coverage, and colour

Perfect for learning C++, experimenting with Linux APIs, or starting small CLI tools.

---

## 📁 Project Structure

```
myproject/
├── include/
│   └── math/
│       └── math.hpp        # Public headers
├── src/
│   ├── lib/
│   │   └── math.cpp        # Library code -> libapp.a
│   └── main.cpp            # Main program entry point
├── tests/
│   └── test_math.cpp       # Unit tests (assert-based)
└── Makefile                # Feature-rich build script
```

---

## 🚀 Building & Running

### Build (Debug by default)

```bash
make
```

### Run the program

```bash
make run
```

Produces:

```
Sum: 8
Product: 15
```

### Clean build files

```bash
make clean
```

---

## 🧪 Running Tests

```bash
make test
```

Example output:

```
[ TEST] bin/tests/test_math
[ PASS] bin/tests/test_math
[ SUMM] Ran 1 test binary(ies): 1 passed
```

---

## 📊 Code Coverage

Install:

```bash
pip install gcovr
```

### Summary

```bash
make coverage
```

### HTML Report

```bash
make coverage-html
```

Opens:

```
coverage/index.html
```

---

## 🔧 Debug vs Release

```bash
make BUILD=Release
```

- Debug: `-O0 -g`
- Release: `-O3 -DNDEBUG`

---

## 🧼 Sanitizers

```bash
make SAN=1
make SAN=1 test
```

---

## 🗄️ Static Library

Files under:

```
src/lib/
```

are built into:

```
build/lib/libapp.a
```

---

## 🧩 Linux API Support (`pkg-config`)

List installed packages:

```bash
make pkgs-list
```

Print flags:

```bash
make pkg-flags PKGS="gtk+-3.0"
```

Build with them:

```bash
make PKGS="gtk+-3.0"
```

---

## 🎨 Colour Output

Disable colours:

```bash
NO_COLOR=1 make
```

---

## 🎯 Summary

This template gives you:

- multi-file C++
- static library
- automatic discovery
- coloured output
- tests
- coverage
- sanitizers
- pkg-config integration

A solid base for any C++ project.
