- - -

# I - The Idea

Every photograph, movie, video game, UI element - it's all an elaborate con job exploiting the specific quirks of human trichromatic vision. Magenta doesn't exist at all, its perception. Brown is just a desaturated orange, again, perception. The beauty of the constraint of human vision is that despite only being able to naturally absorb the color spectrum directly,  our eyes are able to see a multitude of colors purely based on our perception. Take any intensity of red, blue and/or green, mix it, make it dim or bright, place it amongst other colors, and suddenly you have a plethora of colors. SubhanAllah. 

Before I was inspired to create CRIS, I long had a fascination with computer graphics. Man's greatest invention, the computer, is incomplete without a display that manifests its power. We enable the computer to speak to us, by placing millions of tiny led lights in groups of 3: red, blue and green. We have used our retina's natural color preceptors to replicate all colors through light. Group these little green lights into small packets and call them pixels, now you have a set of pixels that span the entire display.  *"Some people say the network is the computer. We believe the display is the computer."* - **Jensen Huang**

I was inspired to create this graphics library when I saw a friend of mine create his own. Given the man of standard that I am, I could not do with a generic name that my friend had chosen. No, I had to go deep. I asked GPT to give me a list of artists that used painting techniques akin to pixels on a display. I stumbled upon Georges Seurat and his textbook technique of pointillism/divisionism. He simply painted countless tiny dots of pure color placed side by side, instead of blending piments on a palette. His entire design hinged on the viewers perception of these colors when placed together. Beautiful isn't it? but it gets better. Seurat was inspired by the works of Chevreul, which I have covered [[ARTH - Chevraul|here.]] It would be redundant for me to go through it again. Nevertheless, that lead me to understand the anatomy of colors. Imagine the feelings I went through when I realize the majority of colors are just in our head. They emerge from relative intensity, adjacency, and contrast.

This is the main inspiration of CRIS. I want to replicate the optical perception of colors by manually editing and controlling every single sub-pixel in the framebuffer. 

> *1/1/2026* 
# II - The Philosophy
Essentially, the screen is just a chunk of memory in the RAM, which we call the framebuffer. Modern graphics library do most of the work for us. We call specific functions like *draw()* or *render()* that manipulate the framebuffer by themselves. For example, if I tell the library to "Draw a red triangle," I am essentially sending a command into a black box. The library talks to the OS, the OS talks to the driver, and the driver talks to the GPU. The GPU then calculates which pixels need to turn red and updates the video memory (VRAM).

While this abstraction is convenient, it prevents us from accessing the raw data required to implement **Chevreul’s Law of Simultaneous Contrast**. To manipulate sub-pixel data based on neighboring colors in real-time, we cannot rely on a pipeline that hides the pixel data from us. We need direct access. Therefore, **CRIS rejects the Black Box.** 

CRIS assumes three things as axioms:
1. A screen is a contiguous block of memory.
2. A pixel is not a color, but a **proposal** to the visual cortex.
3. Perception is programmable.

 This project is meaningful to me in many ways. It's a gateway for me to understand low level memory management, a tool for me to make from the ground up and use for my other projects, including my custom OS, as well as a method through which I learn about computer graphics itself.  But let it be clear, **CRIS IS STILL A GRAPHICS LIBRARY**. My final goal is still to create a full fledge library that I can publicize and use for many different projects. The scientific and optical aspect of CRIS is purely to do justice to the name.
# III - Implementation

## III-A) CRIS Documentation Pipeline & Standards

### 1. Core Philosophy: The "Living Specification"
In the CRIS Engine, documentation is treated as a **Production Artifact**, equal in importance to the C++ Core.
- **Principle:** "If the behavior is not documented, it is Undefined Behavior (UB)."
- **Goal:** To allow a kernel developer to implement the CRIS Host Interface without reading the internal C++ source.
### 2. Documentation Layers
#### Layer 1: In-Code Contracts (The Source of Truth)
Every header file in `Core/` must adhere to the **Strict Tagging Standard**. This is the first line of defense against misuse.
- **@desc:** Functional description.
- **@pur:** Architectural purpose (Why does this exist?).
- **@warn:** Critical safety contracts (Alignment, Lifetimes, Concurrency).
- **@arg:** Parameter constraints (e.g., "Must be non-null").
- **@ret:** Return value and error states (CRIS does not use Exceptions).
**Example:**

```
//@desc: Allocates a contiguous block of memory from the Arena.
//@pur:  Enforces linear allocation to ensure cache locality and zero-fragmentation.
//@warn: Returns nullptr if the Arena is full. Result is always 8-byte aligned.
//@arg:  size_in_bytes - Number of bytes to allocate.
void* Push(usize size_in_bytes);
```

### Layer 2: Architectural Decision Records (ADRs)

We maintain a log of _why_ technical decisions were made, specifically deviations from standard C++ practices.

- **ADR-001:** Rejection of STL (std::vector, std::string) for Kernel Portability.
    
- **ADR-002:** Usage of Linear Memory Arenas over Free Lists.
    
- **ADR-003:** Sub-pixel sampling strategy for Chevreul's Contrast.
    

### Layer 3: The Host Interface Specification

A standalone document defining what the Host OS (Windows, Linux, or Custom Kernel) _must_ provide to CRIS.

- **Memory:** How to hand raw pages to `CRIS::MemoryArena`.
    
- **Input:** The specific struct format for mouse/keyboard events.
    
- **Video:** The contract for the physical framebuffer address.
    

## 3. Development Workflow

The documentation follows the **Code-Lockstep** cycle.

1. **Draft:** Before a new module (e.g., `Framebuffer`) is written, its Header Contract (@tags) is drafted.
    
2. **Implement:** The C++ implementation fulfills the drafted contract.
    
3. **Verify:** During code review, we verify that implementation details (like pointer arithmetic) match the `@warn` tags.
    
4. **Publish:** Doxygen (or standard parser) generates the HTML reference.
    

## 4. Definition of Done (DoD) for Documentation

A feature is not "Done" until:

1. All public methods have `@desc`, `@arg`, and `@ret`.
    
2. Any unsafe pointer operation is explained with a comment.
    
3. Memory ownership is explicitly stated (Who frees this? Answer: The Arena Reset).



















- --
**References**
- **[Screens & 2D Graphics: Crash Course Computer Science #23](https://www.youtube.com/watch?v=7Jr0SFMQ4Rs)**
- 