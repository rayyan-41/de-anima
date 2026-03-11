---
date: 2026-02-06
tags:
  - science
aliases:
  - "1.0 - Neural Networks"
---

- - -
###### %%  Personal Note:
For my MT1008 Multi-Variable Calculus function, I was on a severe time crunch. I had about 4 hours to submit a 10 page Word report on how mathematical concepts such as **gradient descent** and **function optimization** are used in fields of machine learning. I was severely sleep deprived and mentally exhausted but somehow managed to finish it. Admittedly, I used a considerable amount of AI to help me with my work and while that may get me the grade I want for this project, I am not satisfied with my research. This is partially the motivation for this entire section dedicated to the fundamentals of neural networks and machine learning. Here, I'll be properly documenting each and every single thing I learn about in this vast field.  %%
- - -
## 1. Introduction to Machine Learning 
Machine learning is a branch of computer science that focuses on building systems that can learn from data and improve their performance over time without being explicitly programmed. Instead of having a fixed set of instructions, we implement a model that has the capability to ==identify patterns== by training it on datasets. At its core, machine learning combines algorithms, data, and mathematical models to enable computers to "learn" from experience and make intelligent choices. It is the cornerstone of all artificial intelligence systems. 

Python is the most widely used language in the field due to its simplicity and the rich ecosystem of libraries like TensorFlow, PyTorch etc.
- - -
## 2. Neural Networks
#### 2.1 What are Neural Networks
Neural networks are a class of machine learning models inspired by the structure and function of the human brain. They consist of layers of interconnected nodes, called ***neurons***, which process data by assigning ***weights*** to inputs and applying ***activation** **functions*** to determine outputs. 

These layers include an ***input** **layer***, one or more ***hidden** **layers***, and an ***output** **layer***. Neural networks are particularly effective at capturing complex, non-linear relationships in data, making them the backbone of many modern AI applications such as image recognition, natural language processing, and speech analysis
###### Common Terms
- ***==Weights==*** are numerical values that determine the strength and direction of the connection between two neurons in a neural network. When input data passes through the network, each feature is multiplied by its corresponding weight. These weights are adjusted during training to help the model learn the correct relationships between inputs and outputs. Higher absolute values of weights indicate stronger influence on the final prediction.

- ***==Biases==*** are additional parameters added to the input of each neuron before applying the activation function. They allow the model to shift the activation function to better fit the data, making the network more flexible. Without biases, a neural network would be limited in the kinds of patterns it can learn, especially those that don't pass through the origin.

- ***==Activation functions==*** introduce non-linearity into the neural network. After computing the weighted sum of inputs and adding the bias through a formula, the activation function transforms the result into an output signal. Some common activation functions include ReLU ,sigmoid, and tanh. 

- ***==Layers==*** are the building blocks of a neural network. There are typically three types:
	- The *input layer* receives the raw data and passes it forward.
	- *Hidden layers* are intermediate layers where most of the computation and learning take place. A network can have one or many hidden layers.
	- The *output layer* produces the final prediction or classification.  

#### 2.2 How do they work (The Math)
The core idea behind neural networks is *learning through training*. During training, the network adjusts the weights of connections between neurons to minimize the difference between its predictions and the actual results. This is done using a process called ***backpropagation***, combined with an optimization algorithm like ***gradient descent***, which calculates how the weights should change to reduce the overall error. As the model is exposed to more data, it improves its performance. Deeper networks, often called *deep neural networks*, contain many hidden layers and are capable of modeling highly complex patterns, though they also require more computational power and data to train effectively.
###### What is Gradient Descent? 
*Gradient descent* is an optimization algorithm used to minimize the error of a model by adjusting its weights and biases. It works by computing the *gradient* (partial derivatives) of a ***loss function*** with respect to each parameter, which tells us the direction and rate of steepest increase in error. By moving in the opposite direction of the gradient, the algorithm gradually reduces the loss.
###### How Gradient Descent is Used in Training
In neural networks, after making a prediction, the *loss function* calculates the difference between the predicted output and the actual label. Then, gradient descent updates the weights and biases in a way that reduces this loss. This process happens in three main steps:

1. **Forward Pass** – Inputs are passed through the network to produce an output.
2. **Loss Calculation** – The prediction is compared to the true value using a loss function (e.g., MSE or cross-entropy).
3. **Backward Pass (Backpropagation)** – The gradients of the loss with respect to each weight and bias are calculated.
4. **Update Step** – Weights and biases are updated using:

$w = w - α ∂L/∂w$  
$b = b - α ∂L/∂b$

Where:  
- **α** is the *learning rate* (a small positive number that controls the step size)  
- **∂L/∂w** and **∂L/∂b** are the gradients of the loss **L** with respect to weights and biases

This cycle repeats over many **epochs** (full passes through the dataset), gradually improving the model’s accuracy.
###### Formula for Calculating Weighted Sum (Including Bias)
The core operation in a neural network neuron is calculating the weighted sum of inputs plus a bias:

**z = w₁x₁ + w₂x₂ + ... + wₙxₙ + b**

or more compactly in vector form:

**z = w · x + b**

Where:  
- **x** = input vector (x₁, x₂, ..., xₙ)  
- **w** = weight vector (w₁, w₂, ..., wₙ)  
- **b** = bias (a scalar)  
- **z** = the input to the activation function  

After computing **z**, it is passed through an *activation function* to produce the neuron's output:

**a = σ(z)**  
Where **σ** is an activation function like ReLU, sigmoid, or tanh.

#### 2.2 How do they work (The Code)
**Note:** this section only serves as an introduction to the code. Most of the grunt work will be covered in the continuation of this topic [[AI-1.1-Neural Networks Expanded|Here]].

Let's talk about the basic functions.
- ###### What is a Loss Function?
	A *loss function* is a mathematical function that measures how far off a neural network’s predictions are from the actual target values. It quantifies the *error* for a single training example (or a batch), acting as a signal for how well—or badly—the model is performing. The smaller the loss, the better the model’s predictions.
	
	Loss functions are crucial during training because they guide the optimization process. Using *gradient descent*, the network updates its weights and biases to minimize the value of the loss function. Common loss functions include:
	
	- **Mean Squared Error (MSE)** – used for regression tasks  
	  *L = (1/n) Σ (yᵢ - ŷᵢ)²*  
	- **Cross-Entropy Loss** – used for classification tasks (CNNs)
	  *L = - Σ yᵢ log(ŷᵢ)*
	
	Where:  
	- **yᵢ** is the true label  
	- **ŷᵢ** is the predicted probability or value  
	- **n** is the number of samples  
	
	The choice of loss function depends on the type of problem—classification, regression, or something else—and directly affects how the network learns.

---
References:
[But what is a neural network? | Deep learning chapter 1](https://www.youtube.com/watch?v=aircAruvnKk)
[Gradient descent, how neural networks learn | DL2](https://www.youtube.com/watch?v=IHZwWFHWa-w)