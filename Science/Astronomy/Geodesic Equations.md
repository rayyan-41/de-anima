---
date: 2026-04-05
status: complete
tags: [science, astronomy, computation, algorithms, engineering, cli, ai-generated]
note: ""
---

- - -
#### **What are Geodesic Equations?** 
Whilst studying black holes, I found out that light bends around them. I have yet to study more extensively on the nature of light itself but I intend to code the black hole project before that study (though when do I ever follow my own convictions) and so I went ahead and studied more on how they bend on black holes. It has to do with a metric used by mathematicians and physicists to understand the path that light takes around a black hole

See, the space around a black hole is curved. Massive objects like planets and black holes curve spacetime around them (can be studied more in Einstein's theory of relativity). 

> In essence, wherever you have **mass, energy, momentum, or pressure**, spacetime will curve accordingly. That is why planets, stars and blackholes have gravity around them, pulling things closer.

Now a geodesic is a measurement of the shortest path in spacetime. 

- In flat space, it’s just a straight line.
- On a sphere, it’s a great circle (like the equator).
- In curved spacetime, it’s the natural path objects take when no forces are acting — including free-falling planets, spacecraft, or photons near a black hole.

Longitudes are geodesics. Latitudes aren't because they are not the fastest horizontal path a plane could take to go from Islamabad to Baghdad. The geodesic equation is this:

$$
\frac{d^2 x^\mu}{d\lambda^2} + \Gamma^\mu_{\alpha\beta} \frac{dx^\alpha}{d\lambda} \frac{dx^\beta}{d\lambda} = 0
$$
- - -
##### Variables

| Symbol                        | Name                | Explanation                                                                                                                                                                                  |
| ----------------------------- | ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| $$x^\mu$$                     | Coordinates         | Position of the particle in spacetime. can be ($x,y,z$) or ($t,r,\theta$)                                                                                                                    |
| $$\tau$$                      | Proper time         | Time measured by a clock moving with the particle. For light, replaced by an *affine parameter*.                                                                                             |
| $$\frac{dx^\mu}{d\tau}$$      | Four-velocity       | Motion of the particle in spacetime.                                                                                                                                                         |
| $$\frac{d^2 x^\mu}{d\tau^2}$$ | Four-acceleration   | Change of four-velocity with respect to proper time. Vanishes in flat spacetime but not in curved spacetime.                                                                                 |
| $$\Gamma^\mu_{\alpha\beta}$$  | Christoffel symbols | Encode spacetime curvature. Defined as: $\Gamma^\mu_{\alpha\beta} = \tfrac{1}{2} g^{\mu\nu} ( \partial_\alpha g_{\nu\beta} + \partial_\beta g_{\nu\alpha} - \partial_\nu g_{\alpha\beta} )$  |
- - -
##### Key Cases

i) **Flat Spacetime (Minkowski Equation)**: when spacetime is flat, as is the majority of empty space,  $\Gamma^\mu_{\alpha\beta} = 0$. This gives us  $\frac{d^2 x^\mu}{d \tau^2} = 0$, which means that the path followed by an object/light in space is a straight line path with a constant velocity.

ii) **Curved Spacetime**: where $\Gamma^\mu_{\alpha\beta} \neq 0$. Hence, the path followed by an object is a **geodesic**.

## See Also
- [[_Science - Map of Contents|Science MOC]]
