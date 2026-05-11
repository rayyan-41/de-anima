---
date: 2026-04-05
status: complete
tags: [science, computer-science, computation, algorithms, engineering, cli]
note: ""
---

- - -
## I - The Idea

Every photograph, movie, video game, UI element - it's all an elaborate con job exploiting the specific quirks of human trichromatic vision. Magenta doesn't exist at all, its perception. Brown is just a desaturated orange, again, perception. The beauty of the constraint of human vision is that despite only being able to naturally absorb the color spectrum directly, our eyes are able to see a multitude of colors purely based on our perception.

Before I was inspired to create CRIS, I long had a fascination with computer graphics. Man's greatest invention, the computer, is incomplete without a display that manifests its power. We enable the computer to speak to us, by placing millions of tiny led lights in groups of 3: red, blue and green.

I was inspired to create this graphics library when I saw a friend of mine create his own. I asked GPT to give me a list of artists that used painting techniques akin to pixels on a display. I stumbled upon Georges Seurat and his textbook technique of pointillism/divisionism. Seurat was inspired by the works of Chevreul, which I have covered [[Chevreul to Seurat|here]].

## II - The Philosophy

Essentially, the screen is just a chunk of memory in the RAM, which we call the framebuffer. Modern graphics library do most of the work for us. While this abstraction is convenient, it prevents us from accessing the raw data required to implement **Chevreul’s Law of Simultaneous Contrast**.

CRIS assumes three things as axioms:
1. A screen is a contiguous block of memory.
2. A pixel is not a color, but a **proposal** to the visual cortex, which results in a 'perception'.
3. Said perception is programmable.

## III - Implementation

### Phase 1: The Foundation (Freestanding Architecture)
- **Deliverable:** A functional memory arena and type system that compiles without the C++ Standard Library.

### Phase 2: Chevreul's Software Rasterizer (CSR)
- **Deliverable:** A software renderer capable of drawing primitives (lines, triangles) to a windowed context.

### Phase 3: Perception Programming (Chevreul's Law)
- **Deliverable:** A real-time filter that adjusts RGB values based on local neighborhood sampling.

### Phase 4: Sovereign Runtime (Kernel Mode)
- **Deliverable:** The CRIS engine running as the primary interface of a custom OS environment.

- - -
**References**
- [Screens & 2D Graphics: Crash Course Computer Science #23](https://www.youtube.com/watch?v=7Jr0SFMQ4Rs)

## See Also

- [[_Science - Map of Contents|Science MOC]]
