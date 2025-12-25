**Technical Specification & Architecture Guidelines**
**Version: 1.0.0**
**Status:** Draft Ready
-- -
# I - Introduction
**CRIS** (Chevreul Raster Imaging System) is a high-performance, platform-agnostic graphics library designed for dual-environment deployment:

1. **User-Space:** As a lightweight 2D game engine for modern desktop operating systems (Windows/Linux).
2. **Kernel-Space:** As a driver-less graphics subsystem for custom bare-metal operating systems.

The system honors the legacy of **Michel Chevreul** (19th-century color theorist) and **Georges Seurat** (Pointillism) by treating the screen as a strictly mathematical grid of discrete data points.
CRIS eliminates runtime overhead. It does not parse complex formats (PNG/TTF) or manage unpredictable memory allocations at runtime. It relies on a strict Hardware Abstraction Layer (HAL) to bridge the gap between high-level logic and low-level memory buffers.
-- -
# II - Design
To ensure the library remains portable to a custom OS kernel (where standard libraries do not exist), strict coding standards must be enforced.
- **Language:** C++17 or C++20.
- **Compiler Agnostic:** Must compile on MSVC (Windows), GCC (Linux/Cross-Compiler), and Clang.
- **Endianness:** Little-Endian (Standard x86/x64).

### II-2 Language Standards

The C++ Standard Template Library (STL) is **FORBIDDEN** inside the Core Engine.

- **Banned:** `<vector>`, `<string>`, `<iostream>`, `<memory>`, `<thread>`, `<mutex>`
- **Rationale:** These headers rely on OS-specific system calls (syscalls) for memory and I/O that do not exist in a bare-metal kernel.
    
- **Exception:** STL is permitted **only** in the "Asset Cooker" (the offline toolset running on Windows).
    

### 2.3 Feature Restrictions

- **No Exceptions:** `try`, `catch`, and `throw` are forbidden. Error handling must be done via `bool` return values or error codes.
    
    - _Reason:_ Exception handling adds significant runtime overhead and bloat to the binary, which is unacceptable for a kernel.
        
- **No RTTI:** Run-Time Type Information (`dynamic_cast`, `typeid`) is disabled.
    
- **Memory:** No raw `new` or `delete`. All memory allocation must route through the `CRIS::Allocator` interface.
    

---

## 3. Directory Structure

The codebase is organized to separate "Pure Logic" from "Platform Specifics."

Plaintext

```
/CRIS
├── /Core               # Platform-Agnostic Utilities (The Foundation)
│   ├── Allocator.h     # Memory management interfaces
│   ├── Vector.h        # Custom dynamic array (replaces std::vector)
│   ├── String.h        # Custom string class (replaces std::string)
│   ├── Math.h          # SIMD-optimized math (Vec2, Rect, Color)
│   └── Logger.h        # Abstract logging interface
│
├── /Graphics           # The Rendering Pipeline (The Engine)
│   ├── Color.h         # Pixel formats (RGBA8888, RGB565)
│   ├── Texture.h       # Raw pixel container
│   ├── Sprite.h        # Transform logic (Position, Rotation, Scale)
│   ├── Font.h          # Bitmap font renderer
│   └── Renderer.h      # Software Rasterizer (Bresenham, Blitting)
│
├── /Platform           # Hardware Abstraction Layer (The HAL)
│   ├── IWindow.h       # Interface for opening windows
│   ├── IInput.h        # Interface for keyboard/mouse
│   ├── /Win32          # Windows GDI implementation
│   ├── /Linux          # X11 implementation
│   └── /Metal          # Custom OS VESA implementation
│
└── /Assets             # Data Management
    ├── Formats.h       # Binary file specifications (.cris, .cfnt)
    └── Loader.h        # Zero-allocation asset parser
```

---

## 4. The Core Modules

### 4.1 Memory Management (`Core/Allocator.h`)

CRIS must handle memory manually to support Kernel Paging or Linear Allocators.

C++

```
namespace CRIS::Core {
    class IAllocator {
    public:
        virtual void* Allocate(size_t size, size_t alignment = 8) = 0;
        virtual void  Free(void* ptr) = 0;
    };
    
    // Usage: 
    // All CRIS classes usually take an IAllocator* in their constructor.
}
```

### 4.2 Containers (`Core/Vector.h`)

A minimal, robust dynamic array.

- **Must Implement:** Move Semantics (`Vector(Vector&& other)`). This is critical for performance to avoid copying heavy buffers.
    
- **Growth Strategy:** Geometric growth (capacity * 1.5 or 2.0).
    

### 4.3 Mathematics (`Core/Math.h`)

Math structures must be POD (Plain Old Data) to ensure they can be `memcpy`'d and passed to SIMD registers.

C++

```
struct Vec2i { int32_t x, y; };      // Screen Coordinates
struct Vec2f { float x, y; };        // World Coordinates (Physics)
struct Rect  { int32_t x, y, w, h; }; 
```

---

## 5. The Graphics Pipeline (Software Rasterizer)

CRIS uses a "Soft-Backend" by default. It assumes no GPU is available.

### 5.1 The Framebuffer

The abstract representation of the screen.

C++

```
struct Framebuffer {
    uint32_t* pixels; // The raw memory address (0xB8000 or VirtualAlloc)
    int width;        // Screen Width
    int height;       // Screen Height
    int pitch;        // Bytes per row (Width * 4 + Padding)
};
```

### 5.2 The Renderer (`Graphics/Renderer.h`)

The engine that manipulates the framebuffer.

- **`Clear(Color c)`**: Uses `memset` (or 64-bit wide fills) to wipe the screen.
    
- **`PutPixel(x, y, c)`**: Safety-checked pixel write.
    
- **`DrawLine(p1, p2, c)`**: Implementation of **Bresenham's Line Algorithm** (Integer math only).
    
- **`Blit(Texture* tex, Rect src, Rect dst)`**:
    
    - The workhorse function.
        
    - Must support Alpha Blending via the formula:
        
        $$Result = (Source \times \alpha) + (Dest \times (1 - \alpha))$$
        
    - _Optimization:_ This function is the primary candidate for **SIMD (SSE/AVX)** optimization later.
        

---

## 6. The Asset Ecosystem (The "Cooker")

CRIS does not load PNGs. It loads "Cooked" binaries.

Workflow: Source.png $\to$ [Asset Cooker Tool] $\to$ Asset.cris $\to$ [CRIS Engine]

### 6.1 Texture Format (`.cris`)

A flat binary dump designed for instant loading (`fread` $\to$ RAM).

|**Offset**|**Type**|**Name**|**Description**|
|---|---|---|---|
|0x00|`char[4]`|Signature|Magic bytes: "CRIS" (`0x43 52 49 53`)|
|0x04|`uint8`|Type|0x01 = Texture, 0x02 = SpriteSheet|
|0x05|`uint8`|Format|0x20 = RGBA8888, 0x10 = RGB565|
|0x06|`uint16`|Width|Texture width in pixels|
|0x08|`uint16`|Height|Texture height in pixels|
|0x0A|`byte[]`|Data|Raw Pixel Data (Size = W * H * BPP)|

### 6.2 Font Atlas Format (`.cfnt`)

Pre-rasterized font data.

- **Concept:** A single `.cris` texture containing a grid of all letters, plus a binary table (The "Glyph Map") describing the coordinates of each letter.
    
- **Benefit:** Allows using any font (Arial, Times New Roman) in the OS without needing a TrueType rasterizer.
    

---

## 7. The Hardware Abstraction Layer (HAL)

To port CRIS, one simply implements the `IWindow` interface.

### 7.1 The Interface

C++

```
class IWindow {
public:
    virtual bool Open(int width, int height, const char* title) = 0;
    virtual bool PollEvents() = 0;
    
    // The "SwapBuffers" command.
    // In Windows: Calls StretchDIBits
    // In OS: Calls memcpy to VESA Buffer
    virtual void Present(const Framebuffer& backBuffer) = 0;
    
    virtual bool IsKeyDown(KeyCode key) = 0;
};
```

### 7.2 Implementation Strategies

|**Feature**|**Windows Implementation (Win32Window.cpp)**|**Custom OS Implementation (MetalWindow.cpp)**|
|---|---|---|
|**API**|`windows.h` (GDI)|VESA VBE / UEFI GOP|
|**Input**|`PeekMessage` loop (WM_KEYDOWN)|PS/2 Keyboard Port (0x60) polling|
|**Memory**|`VirtualAlloc`|Physical Memory Manager|
|**Output**|`StretchDIBits` to HWND|`memcpy` to `0xE0000000` (LFB)|

---

## 8. Implementation Roadmap

### Phase 1: The Foundation (Windows User-Mode)

1. Implement `Core` (Vector, Math, Allocator).
    
2. Implement `Graphics/Renderer` (Software Rasterizer).
    
3. Implement `Platform/Win32` to open a Debug Window.
    
4. **Goal:** Draw a red rectangle on a black screen.
    

### Phase 2: The Toolchain (The Cooker)

1. Write a simple Console App (using `stb_image.h`).
    
2. Reads `.png`, writes `.cris`.
    
3. Update Engine to load `.cris` files.
    
4. **Goal:** Draw a sprite on the screen.
    

### Phase 3: The Kernel Port (Bare Metal)

1. Copy the `/Core` and `/Graphics` folders to the OS project.
    
2. Implement `Platform/Metal`.
    
3. Map the `Framebuffer` struct to the address provided by the Bootloader (GRUB/Limine).
    
4. **Goal:** The exact same "Draw Sprite" code works on the OS.
    

---

## 9. Coding Conventions

- **Naming:**
    
    - Classes/Functions: `PascalCase` (`Texture::Load`, `Renderer::Draw`)
        
    - Variables: `camelCase` (`backBuffer`, `pixelIndex`)
        
    - Constants: `SCREAMING_SNAKE` (`MAX_SPRITES`, `SCREEN_WIDTH`)
        
    - Private Members: Prefix `m_` (`m_width`, `m_height`)
        
- **Safety:**
    
    - Always assert preconditions in Debug mode (`ASSERT(ptr != nullptr)`).
        
    - Use `nullptr` instead of `NULL`.
        
    - Use fixed-width integers (`uint32_t`) for binary file structures.