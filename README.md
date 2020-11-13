# Movie Shot Scheduling Problem

By Walter Sebastian Gisler, November 2020

A comparison of different methods to solve the Movie Shot Scheduling problem (MSS).

The MSS Problem is a hard combinatorial problem. The objective is to decide on the sequence in which different scenes for a movie are shot. Each scene requires one or more actors and is shot at one location. Actors can be part of multiple scenes and locations can be used for multiple scenes too. Using a location more than once costs more than shooting all the scenes at the same location one after the other. Similarly, the more days an actor needs to be available (from his/ her first scene until the last one), the more expensive this actor will be. Locations have different costs and each actor has a daily rate. In addition to this, there are some precedence constraints, which are used to express the requirement that a scene can only be shot when a second scene is already recorded.

A more detailed definition of the problem can be found in the following papers:
- Bomsdorf and Derigs, OR Spectrum, 30(4):751–772, 2008: https://link.springer.com/article/10.1007/s00291-007-0103-6
- Cheng et al, Journal of Optimization Theory and Applications, 79(3):479–492, 1993: http://www.dcs.gla.ac.uk/~pat/cpM/jchoco/rehersalProblem/opt1993.pdf

Problem instances were taken from Optimization Hub: https://opthub.uniud.it/problem/mss

# Methods

We are comparing the following solution methods:

- Brute Force (Just used to generate initial solutions)
- Mixed Integer Programming
- Constraint Programming (Using CP Optimizer)
- A custom made simulated annealing optimizer (implemented using Cython, for performance reasons)
- A custom made genetic algorithm

# Performance

Both the MIP and the CP Optimizer approach work well for smaller instances, but are not usable at all for the larger instances. The simulated annealing (SA) approach works extremely well for all instances. It finds the optimum for the smaller instances and it finds very high quality solutions for the larger instances quickly. For example, for the largest instances (300 scenes), the SA optimizer finds a solution that is 0.4% more expensive than the best known solution (found with LocalSolver) in under one hour.

To my surprise, the GA optimizer doesn't perform too well. It is better than the MIP or CP optimizer for larger instances, but it falls far behind the SA approach. I used a a crossover operation that is commonly used for the travelling salesman problem or other sequencing problems. A different crossover operation might improve the performance a bit. There is an option to run the GA approach for multiple populations and then combine the best solutions of all of these populations into a new population. The idea behind this is to keep the populations heterogenous. I think this is a point that could still be improved significantly with a more intelligent way of mixing up the populations. Another thing that would help is to keep track of the similarity of the solutions and expand the population size when the solutions are getting too similar and allow more mutations.

# Running this

In order to run this, you need to have the Cython package installed (pip install cython) and also a C compiler. This should already be the case on Mac and Linux, but on Windows it is necessary to install the Visual Studio C/C++ build tools. Before running the main file, you need to compile the Cython code: "python setup.py build_ext --inplace". Once that is done, you can just run "python main.py". The main file contains several algorithms and it is up to you to chose one of these optimization techniques and play around with its parameters.