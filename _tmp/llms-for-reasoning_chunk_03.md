## Mechanism 1: Prompt-Based Structured Thinking (In-Context Search)

*Thesis: Large Language Models reason by externalizing their cognitive processes into structured, step-by-step linguistic outputs. This forces the model to transform static, single-pass word prediction into a dynamic, algorithmic search space where logic can be evaluated and refined.*

To understand how an LLM reasons, we must first confront what it naturally does *not* do. At its absolute core, an LLM is a statistical engine trained to predict the next most probable token in a sequence. If asked a complex mathematical question and forced to answer immediately, the model acts reactively, attempting to guess the final answer in a single, linear pass based purely on the statistical weight of the prompt. This "fast thinking" often fails for complex logic.

To perform genuine, multi-step reasoning, LLMs must break out of this reactive generation. They achieve this through prompt-based structured thinking, a mechanism where the model is forced to explicitly write out its intermediate logical steps before arriving at a final conclusion [1]. 

### The Cognitive Scratchpad: Chain-of-Thought (CoT)

The foundational technique for this is known as Chain-of-Thought (CoT) reasoning. By prompting the model to "think step by step," the LLM externalizes its internal computations into natural language [1]. 

When the model generates an intermediate step (e.g., "First, I need to calculate the area of the circle..."), that generated text is immediately fed back into the model's own context window as input for the next token prediction. By writing out its "thoughts," the model is essentially generating a cognitive scratchpad [1]. This scratchpad changes the probabilistic landscape of the model; instead of predicting the final answer from the original question, it is now predicting the *next logical step* based on the *previous logical step* it just wrote. This massively reduces compounding errors and aligns the statistical output with valid logical progression.

### Branching Logic: Tree of Thoughts (ToT) and Graph of Thoughts (GoT)

However, linear Chain-of-Thought reasoning is still prone to accumulating errors if a single early step is flawed. To counter this, advanced reasoning mechanisms structure these externalized thoughts into complex, multi-dimensional pathways, mimicking human deliberation or "slow thinking" [2].

1. **Tree of Thoughts (ToT)**: The ToT framework allows the model to branch its reasoning into multiple possible, divergent paths rather than committing to a single line of logic [3]. The LLM generates several distinct intermediate thoughts, evaluates the viability of each (often scoring them), and then uses classical computer science search algorithms—such as Breadth-First Search (BFS), Depth-First Search (DFS), or Monte Carlo Tree Search (MCTS)—to explore the most promising branches [3][4]. Crucially, if the model realizes a branch leads to a logical dead end, it can backtrack and pursue a different path, exhibiting genuine planning and self-correction.
2. **Graph of Thoughts (GoT)**: Taking this structural complexity further, the Graph of Thoughts (GoT) method models these individual thoughts as interconnected vertices on a network graph [3][5]. Unlike a tree, which only branches outward, a graph allows pathways to converge. This means the LLM can combine, synergize, and merge different pieces of logic from disparate reasoning paths to deduce a final, synthesized answer [5]. 

Through these mechanisms, the LLM stops being a simple text generator and becomes an active agent searching through a self-generated landscape of logic.
