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

# Performance

Both the MIP and the CP Optimizer approach work well for smaller instances, but are not usable at all for the larger instances. The simulated annealing (SA) approach works extremely well for all instances. It finds the optimum for the smaller instances and it finds very high quality solutions for the larger instances quickly. For example, for the largest instances (300 scenes), the SA optimizer finds a solution that is 0.4% more expensive than the best known solution (found with LocalSolver) in under one hour.

# To do

- Implement a genetic algorithm