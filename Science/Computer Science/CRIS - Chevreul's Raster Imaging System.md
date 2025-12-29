- - -
# I - Abstract

Most of us look at a screen and see a grid of colored squares. We assume that if we tell the computer to draw a red pixel at coordinate (10, 10), the job is done. But this is a simplification—a comfortable lie that modern graphics drivers tell us so we don't have to worry about the physics of light.

The truth is that a "pixel" does not exist. What we call a pixel is actually three distinct microscopic lightbulbs—Red, Green, and Blue—sitting side-by-side. When you look at a monitor, you aren't looking at a solid image; you are looking at a mosaic of millions of tiny, separate lights that your brain desperately tries to blend into a coherent picture.

CRIS is a graphics library built on the realization that we can exploit this mechanism.

Named after Michel Eugène Chevreul, the 19th-century French chemist who formulated the "Law of Simultaneous Contrast," CRIS is an attempt to build a graphics engine that prioritizes optical truth over mathematical simplicity. Chevreul discovered that a color is not absolute; its appearance is entirely dictated by the colors surrounding it.1 A grey spot looks white on a black background and dark on a white one. While standard graphics engines (like those powering OpenGL or SFML) ignore this phenomenon, treating every pixel as an isolated mathematical island, CRIS embraces it.

At its heart lies the CSR (Chevreul Software Rasterizer), a freestanding rendering core that does not rely on the GPU. Instead of sending commands to a graphics card and hoping for the best, CSR treats the screen as a raw array of memory. It takes total ownership of every byte. This allows us to perform "Sub-pixel Rendering"—manipulating the individual Red, Green, and Blue stripes within a pixel to effectively triple the horizontal resolution of the display. We aren't just drawing shapes; we are tuning the interference patterns of light to make edges look sharper and text look clearer than the screen's physical resolution should allow.

To achieve this level of precision, CRIS had to be built differently. It is not a wrapper around existing drivers. It is a "bare-metal" engine written in C++20 with a strict "No-STL" architecture. It does not use standard vectors or memory managers that hide the hardware from the programmer. Instead, CRIS acts as its own operating system for graphics: it allocates a single contiguous block of RAM (a Memory Arena) and manages the lifecycle of every bit manually. This makes the library incredibly lightweight and platform-agnostic. It can run on a high-end Windows gaming PC, a Linux server, or a custom-built embedded device with no operating system at all.

We are not building CRIS to compete with the raw polygon-pushing power of modern game engines. We are building it to reclaim control. By moving the rendering logic back to the CPU and applying 19th-century color theory to 21st-century hardware, we are creating a tool that produces visuals with a unique, "high-contrast" signature—images that are mathematically constructed to be perceived as perfectly sharp by the human eye.

CRIS is an experiment in optical engineering, a challenge to the standard rendering pipeline, and a love letter to the raw manipulation of light.