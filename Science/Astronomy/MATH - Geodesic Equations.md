DATE: 2026-02-06
TAGS: #science #physics #mathematics #relativity #geodesic #ai-generated
- - -
### MATH - Geodesic Equations

#### **What are Geodesic Equations?**

Whilst studying black holes, I found out that light bends around them. I have yet to study more extensively on the nature of light itself but I intend to code the black hole project before that study (though when do I ever follow my own convictions) and so I went ahead and studied more on how they bend on black holes. It has to do with a metric used by mathematicians and physicists to understand the path that light takes around a black hole.

See, the space around a black hole is curved. Massive objects like planets and black holes curve spacetime around them. 

> In essence, wherever you have **mass, energy, momentum, or pressure**, spacetime will curve accordingly. That is why planets, stars and blackholes have gravity around them, pulling things closer.

Now a geodesic is a measurement of the shortest path in spacetime. 

- In flat space, it’s just a straight line.
- On a sphere, it’s a great circle (like the equator).
- In curved spacetime, it’s the natural path objects take when no forces are acting.

The geodesic equation is this:

$$\frac{d^2 x^\mu}{d\lambda^2} + \Gamma^\mu_{\alpha\beta} \frac{dx^\alpha}{d\lambda} \frac{dx^\beta}{d\lambda} = 0$$

- - -
##### Variables

| Symbol | Name | Explanation |
| :--- | :--- | :--- |
| $$x^\mu$$ | Coordinates | Position of the particle in spacetime. |
| $$\tau$$ | Proper time | Time measured by a clock moving with the particle. |
| $$\frac{dx^\mu}{d\tau}$$ | Four-velocity | Motion of the particle in spacetime. |
| $$\frac{d^2 x^\mu}{d\tau^2}$$ | Four-acceleration | Change of four-velocity with respect to proper time. |
| $$\Gamma^\mu_{\alpha\beta}$$ | Christoffel symbols | Encode spacetime curvature. |

- - -
##### Key Cases

i) **Flat Spacetime (Minkowski Equation)**: when spacetime is flat, $\Gamma^\mu_{\alpha\beta} = 0$. This means the path is a straight line.

ii) **Curved Spacetime**: where $\Gamma^\mu_{\alpha\beta} \neq 0$. The path is a **geodesic**.


