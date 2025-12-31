- - -
# Abstract
## I - The Idea

Every photograph, movie, video game, UI element - it's all an elaborate con job exploiting the specific quirks of human trichromatic vision. Magenta doesn't exist at all, its perception. Brown is just a desaturated orange, again, perception. The beauty of the constraint of human vision is that despite only being able to naturally absorb the color spectrum directly,  our eyes are able to see a multitude of colors purely based on our perception. Take any intensity of red, blue and/or green, mix it, make it dim or bright, place it amongst other colors, and suddenly you have a plethora of colors. SubhanAllah. 

Before I was inspired to create CRIS, I long had a fascination with computer graphics. Man's greatest invention, the computer, is incomplete without a display that manifests its power. We enable the computer to speak to us, by placing millions of tiny led lights in groups of 3: red, blue and green. We have used our retina's natural color preceptors to replicate all colors through light. Group these little green lights into small packets and call them pixels, now you have a set of pixels that span the entire display.  *"Some people say the network is the computer. We believe the display is the computer."* - **Jensen Huang**

I was inspired to create this graphics library when I saw a friend of mine create his own. Given the man of standard that I am, I could not do with a generic name that my friend had chosen. No, I had to go deep. I asked GPT to give me a list of artists that used painting techniques akin to pixels on a display. I stumbled upon Georges Seurat and his textbook technique of pointillism/divisionism. He simply painted countless tiny dots of pure color placed side by side, instead of blending piments on a palette. His entire design hinged on the viewers perception of these colors when placed together. Beautiful isn't it? but it gets better. Seurat was inspired by the works of Chevreul, which I have covered [[ARTH - Chevraul|here.]] It would be redundant for me to go through it again. Nevertheless, that lead me to understand the anatomy of colors. Imagine the feelings I went through when I realize the majority of colors are just in our head. They emerge from relative intensity, adjacency, and contrast.

This is the main inspiration of CRIS. I want to replicate the optical perception of colors by manually editing and controlling every single sub-pixel in the framebuffer. 

> *1/1/2026* 
## II - The Technicalities
### i) Concept
Essentially, the screen is just a chunk of memory in the RAM, which we call the framebuffer. Modern graphics library do most of the work for us. We call specific functions like *draw()* or *render()* that manipulate the framebuffer by themselves. For example, if I tell the 


CRIS assumes three things as axioms:
1. A screen is a contiguous block of memory.
2. A pixel is not a color, but a **proposal** to the visual cortex.
3. Perception is programmable.

### ii) Implementation















- --
**References**
- **[Screens & 2D Graphics: Crash Course Computer Science #23](https://www.youtube.com/watch?v=7Jr0SFMQ4Rs)**
- 