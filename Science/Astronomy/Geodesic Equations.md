**What are Geodesic Equations?** 
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


**Coordinates (\(x^\mu\))**
  - Position of the particle in spacetime.
  - Index range: 
$$
    \mu = 0,1,2,3 \quad \Rightarrow \quad (t, x, y, z) \;\text{or}\; (t, r, \theta, \phi)
    $$

- **Proper Time (\(\tau\))**
  - The time measured by a clock moving with the particle.
  - For light (massless particles), use an *affine parameter* instead.

- **Four-Velocity (\(\frac{dx^\mu}{d\tau}\))**
  - Describes the motion of the particle in spacetime.

- **Four-Acceleration (\(\frac{d^2 x^\mu}{d \tau^2}\))**
  - Change of four-velocity with respect to proper time.
  - In curved spacetime, this does not vanish even for free-fall.

---

2. Christoffel Symbols (\(\Gamma^\mu_{\alpha\beta}\))

- Represent how spacetime curvature affects motion.
- Defined from the metric tensor \(g_{\mu\nu}\):

$$
\Gamma^\mu_{\alpha\beta} = \tfrac{1}{2} g^{\mu\nu} 
\left( \partial_\alpha g_{\nu\beta} + \partial_\beta g_{\nu\alpha} - \partial_\nu g_{\alpha\beta} \right)
$$

- Not tensors, but act like "gravitational force terms" in curved coordinates.

---

## 3. Special Cases

- **Flat spacetime (Minkowski)**
  $$
  \Gamma^\mu_{\alpha\beta} = 0
  $$
  Equation reduces to:
  $$
  \frac{d^2 x^\mu}{d \tau^2} = 0
  $$
  → motion is a straight line at constant velocity.

- **Curved spacetime**
  $$
  \Gamma^\mu_{\alpha\beta} \neq 0
  $$
  Motion follows a **geodesic**, the curved generalization of a straight line.

---

## 4. Intuition

- The geodesic equation is the **relativistic equivalent of Newton’s first law**:  
  > "A free particle continues along the straightest possible path, unless acted on."  
- In flat spacetime: straight line.  
- In curved spacetime: curved path determined by spacetime geometry.