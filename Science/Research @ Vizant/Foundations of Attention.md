---
date: 2026-08-01
status: complete
tags: [science, research, overview, machine-learning, foundations-of-attention, manual]
note: ""
---

**Rayyan Ahmad Sultan**
**circa 14th April 2026**
# Introduction 
To even take an attempt at understanding what attention is, first we must establish the mathematical context within which it takes residence. Linear Algebra as we know it today has been vastly shaped by many notable figures of history that introduced groundbreaking concepts and innovative tools which enable modern day processors to run thousands upon thousands of calculations in fractions of a second. 'Foundations of Attention' aims to equip the reader with all the prerequisite knowledge they require to understand how the attention mechanism, a key part of LLMs, functions. 

Before we begin, I must highlight a fascinating discovery in regards to the history of mathematics that I was unfortunately not aware of. Hermann Grassman is a foundational figure in the philosophical and theoretical dimension of Linear Algebra. His work is responsible for enabling us to decouple vectors from observable reality. Before his "Theory of Extension", vectors were limited to 3 dimensions, reflecting reality and our observable space. His work established vectors as pure mathematical tools which we can use to represent complex, multi-faceted data. In fact, this is exactly the concept that makes vector embedding models even work. A 768 or 1000+ dimension vector can only be conceived once vectors themselves are separated from the world and are abstracted enough. I hope this small note sparked an interest in mathematics in you just like it did in me.

Nevertheless, I assume that the reader already knows about the basics of machine learning i.e. neural networks, backpropagation, gradient descent, cosine similarity etc. We will explore why these concepts are important, how they tie into the concept of attention, ultimately setting the ground for attention itself. Let's begin.
- - -
# The Problems That Arise With Neural Networks
There are two distinct problems that we need to discuss before we proceed to more complex topics. 
#### The Problem of Linearity
A neural network without activation functions would completely collapse the math that drives backpropagation.  When you stack a linear equation on top of another, you get just another linear equation: 

Take **this equation for example:** $$y = Wx + b$$This is what happens when you add the previous layer's equation into **this one:** 
$$y = W_2(W_1x + b_1) + b_2$$ $$y = (W_2W_1)x + (W_2b_1 + b_2)$$ $$y = W'x + b'$$This proves that without an activation function, multiple layers simplify into a single linear transformation, which completely defeats the purpose of a neural network. This is not regression, we do not require a straight line to dissect information accurately, we require complex divisions and weights/biases for each layer to recognize deep rooted patterns. Therefore, we require **Activation Functions**.  

By adding a non-linear activation function ($f$) after every layer, we prevent the weight matrices ($W_1$, $W_2$) from being factored together: $$y = W_2 f(W_1x + b_1) + b_2$$
Here, *f* denotes an activation function. Many exist, and we will get to the relevant ones in a second. The takeaway is that activation functions are essential. Now, this dependance results in another problem, arguably the biggest obstacle for NLP so far. 

### The Problem of The Chain Rule
When a network makes an error, it uses backpropagation to adjust its weights. It must learn from mistakes. This relies on the Chain Rule from calculus to send the error signal backward. (derivative of the loss function). The Chain Rule for a single weight matrix:

$$\frac{\partial L}{\partial W_1} = \frac{\partial L}{\partial y} \cdot \frac{\partial y}{\partial h} \cdot \frac{\partial h}{\partial W_1}$$

$\frac{\partial L}{\partial W_1}$ is the final gradient (how much to change the weight). $\frac{\partial y}{\partial h}$ is the exact point where the derivative of the activation function is multiplied into the chain. If the activation function has a derivative of zero, the chain rule multiplies the error signal by zero, the gradient vanishes, and the network stops learning. This is what we call the Vanishing Gradient Problem.

So this means it is very important for us to choose the right activation functions. Now early networks used a strict threshold, in the form of the step function, mimicking biological neurons. However, its derivative is zero almost everywhere, killing the gradient.

$$f(x) = \begin{cases} 0 & \text{if } x < 0 \\ 1 & \text{if } x \ge 0 \end{cases}$$

- Derivative: $f'(x) = 0 \quad (\text{for } x \neq 0)$
Sigmoid provided a smooth curve with a computable derivative, but its maximum derivative is too small (0.25). Multiplying this across deep networks causes the signal to decay exponentially (The Vanishing Gradient Problem).
$$\sigma(x) = \frac{1}{1 + e^{-x}}$$
- Derivative:$$\sigma'(x) = \sigma(x)(1 - \sigma(x))$$
**Proof of the 0.25 Limit:** To find the maximum possible value of this derivative, we substitute $\sigma(x)$ with a variable $S$:

$$y = S(1 - S) = S - S^2$$

To find the peak of this downward-facing parabola, we take the derivative with respect to $S$ and set it to zero:

$$\frac{dy}{dS} = 1 - 2S = 0 \implies S = 0.5$$

Plugging $S = 0.5$ back into our derivative equation gives the absolute maximum:

$$\text{Max} = 0.5 \cdot (1 - 0.5) = 0.25$$

Because the maximum multiplier is $0.25$, backpropagation through deep networks continuously multiplies fractions (e.g., $0.25 \times 0.25 \times 0.25 \dots$), causing the gradient to vanish exponentially.

Even though there are other activation functions in existence, these are the most relevant and that is because they do well to highlight the problem that arose, and even though the industry uses much better functions, the sigmoid function will still remain an important part of LLMs because the attention mechanism is dependent on a generalization of this very function, and the paper "Attention is all you need" completely sidesteps the entire architecture.
# Vector Embeddings: The Building Blocks
Before getting to attention, let's quickly go over one more thing: how the vectors we described are designed before they are sent to the neural network for training. The most obvious idea was **One-Hot Encoding.** 
	In one-hot encoding (sparse vectors), a vocabulary of 50,000 words means a 50,000-dimensional vector consisting of 49,999 zeros and a single `1`. It is incredibly inefficient, and mathematically, every word is exactly $90^\circ$ apart (cosine similarity is $0$). One-hot vectors cannot capture meaning, only existence. Technically valid, semantically useless. Geometrically, every word sits at the same distance from every other word. This representation would insist that "cat" is precisely as related to "dog" as it is to "democracy" or "Thursday." Every shred of meaning has been thrown away before the network even begins. 

To counter this, what we instead do is use **dense embeddings** in which every word is assigned a vector of dimension $d_{dim} = 512$ or more, every entry a random number, not 0 which are then treated as parameters, adjusted by backpropagation. Over training, the model itself would learn all there is to learn about the word in the given context or independently, and we discover something very fascinating: words with similar meanings have similar vectors.  This is what we call **distributional hypothesis**, first discovered by Chomsky's teacher **Zellig Harris**. 

The most important paper in this domain is the "Word2Vec" paper by **Tomas Mikolov** who discovered that words, as vectors, constitute more than just semantic significance; they had underlying directional relationships with other word vectors, and therefore could be added and subtracted to give a resultant vector that represents another word. The most frequently taught example is the $v_{king} - v_{man} + v_{woman} = v_{queen}$  example. 

Every single AI model you download has something called an **Embedding Matrix** stored inside it. The matrix contains all the worlds learned by the model, in the form of vectors (well, actually tokens, but that is a separate topic. For simplicity, let's assume vectors).  Mathematically it is denoted as:
$$E \in \mathbb{R}^{|V| \times d_{model}}$$
- - -
# Sequence Models
So far, we have setup the foundations of how machines represent words as numbers and how they learn through the calculus of backpropagation. But language is not just a bag of words; it is a sequence of time. Before 2017, the prevailing logic was that to understand a sentence, a neural network had to read it exactly like a human does: one word at a time, from left to right. This assumption gave rise to **Sequence Models**.

1) **Recurrent Neural Networks**: This neural network was outfitted with *short term memory* in the form of a hidden fixed-sized vector $h_t$. It kept a running summary of everything said so far (as in dissecting the prompt one word at a time from left to right). After the final word, $h_t$ would have a running summary of the entire input. 
$$ \mathbf{h}_t = \tanh(\mathbf{W}_{hh} \mathbf{h}_{t-1} + \mathbf{W}_{xh} \mathbf{x}_t + \mathbf{b}) $$

	Here is what each piece of that equation is doing:
	- **$\mathbf{h}_t$**: The new hidden state for the current step. This is the updated "summary."
	- **$\tanh$**: The hyperbolic tangent activation function. It squishes the resulting calculations into a range between -1 and 1, keeping the values stable as the network loops over and over.
	- **$\mathbf{W}_{hh} \mathbf{h}_{t-1}$**: This is where the "memory" comes in. The network takes the _previous_ hidden state ($\mathbf{h}_{t-1}$) and multiplies it by a dedicated weight matrix ($\mathbf{W}_{hh}$) to decide what past context to bring forward.
	- **$\mathbf{W}_{xh} \mathbf{x}_t$**: This handles the _new_ information. The network takes the current input word ($\mathbf{x}_t$) and multiplies it by its own weight matrix ($\mathbf{W}_{xh}$).    
	- **$\mathbf{b}$**: A standard bias vector to shift the activation function.
    
	Essentially, the network combines the past ($\mathbf{h}_{t-1}$) with the present ($\mathbf{x}_t$), squishes it through a $\tanh$ function, and outputs the new memory state ($\mathbf{h}_t$).

This elegant equation worked perfectly for reading a sequence. But a fatal flaw was hidden in the math, and it only revealed itself when the network tried to _learn_. Neural networks learn through backpropagation, but standard backpropagation is designed for straight lines, not temporal loops. To train an RNN, researchers had to conceptually "unroll" it. A 20-word sentence became a 20-layer deep network.

In standard networks, you might recall that activation functions like Sigmoid or $\tanh$ naturally squish gradients toward zero over many layers. RNNs suffer from this same squish, but they introduce a second, fatal compounding factor: the recurrent weight matrix, $\mathbf{W}_{hh}$. Because the RNN is a loop, the chain rule dictates that stepping backward through time requires multiplying the error by $\mathbf{W}_{hh}$. To step back 20 words means multiplying by $\mathbf{W}_{hh}$ 20 times. Combined with the $\tanh$ squish, this repeated exponentiation makes the gradient incredibly volatile, resulting in either a vanishing or exploding gradient. The most important takeaway is that the error signal simply vanishes. The network can easily update its understanding of the final words in a sentence, but it suffers total amnesia regarding the beginning. It became mathematically impossible for an RNN to connect a subject at the start of a long paragraph to a verb at the end.

2) **Long Short-Term Memory Models**: The holy grail of sequence models pre-2017.  Their entire purpose was to fix the vanishing memory of RNNs. They did so by introducing a new mechanism: **gating**. Instead of blindly overwriting their memory at every single time step, LSTMs learned how to forget. By giving the network the ability to selectively drop irrelevant past context and write new, critical information into an internal 'cell state', the vanishing gradient problem was finally tamed.
Note that it was tamed, not *solved*. 