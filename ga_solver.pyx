from solution import Solution
from time import time
from random import random, shuffle, randint, choice
from math import exp
from multiprocessing import Process, Queue
import os, subprocess

cdef class GeneticAlgorithmSolver:
    cdef problem

    def __init__(self, problem):
        self.problem = problem

    cdef crossover(self, c1, c2, mutation_probability = 0.2):
        cdef int crossover_point, i1, i2
        cdef list c1_tail, c2_tail, new_c1_seq, new_c2_seq
        cdef temp
        
        crossover_point = randint(1, c1.get_num_scenes()-2)
        
        c1_tail = [c1.get_sequence(i) for i in range(crossover_point, c1.get_num_scenes())]
        c2_tail = [c2.get_sequence(i) for i in range(crossover_point, c2.get_num_scenes())]
        
        new_c1_seq = [c1.get_sequence(i) for i in range(c1.get_num_scenes()) if c1.get_sequence(i).id not in [sc.id for sc in c2_tail]]
        new_c1_seq = new_c1_seq + c2_tail
        # if random() < mutation_probability:
#             i1 = randint(0,len(new_c1_seq)-1)
#             i2 = randint(0,len(new_c1_seq)-1)
#             temp = new_c1_seq[i1]
#             new_c1_seq[i1] = new_c1_seq[i2]
#             new_c1_seq[i2] = temp
        new_c2_seq = [c2.get_sequence(i) for i in range(c2.get_num_scenes()) if c2.get_sequence(i).id not in [sc.id for sc in c1_tail]]
        new_c2_seq = new_c2_seq + c1_tail
        # if random() < mutation_probability:
#             i1 = randint(0,len(new_c2_seq)-1)
#             i2 = randint(0,len(new_c2_seq)-1)
#             temp = new_c2_seq[i1]
#             new_c2_seq[i1] = new_c2_seq[i2]
#             new_c2_seq[i2] = temp
        
        return Solution(self.problem, new_c1_seq), Solution(self.problem, new_c2_seq)
        
    cdef mutation(self, c, num_mutations = 10):
        cdef int i1, i2, i
        cdef list c_seq
        cdef temp
        
        c_seq = [c.get_sequence(i) for i in range(0, c.get_num_scenes())]
        
        for i in range(num_mutations):
            i1 = randint(0,len(c_seq)-1)
            i2 = randint(0,len(c_seq)-1)
            temp = c_seq[i1]
            c_seq[i1] = c_seq[i2]
            c_seq[i2] = temp
        
        return Solution(self.problem, c_seq)
        
    
    cpdef multi_population_solve(self, population_size = 50, num_populations = 5, num_mates = 3, num_generations = 100, num_repetitions = 10, mutation_probability = 0.2, num_mutations = 10, num_random_solutions_to_keep = 10):
        """
        This solver will generate num_populations independent populations and run the solver on those. After those populations are generated, the top solutions from all populations are combined into one new population and the process starts again
        """
        populations = []
        for i in range(num_repetitions):
            new_populations = []
            for j in range(num_populations):
                new_populations.append(self.solve(population_size, num_mates, num_generations, mutation_probability, num_mutations, num_random_solutions_to_keep, populations))
                populations = [] # we only want the very first population to be using the previous populations as a "seed"
            populations = new_populations
            for sol in populations:
                sol.write('solution/' + str(sol.compute_cost()) + '.mss')

    cpdef solve(self, population_size = 50, num_mates = 3, num_generations = 10000, mutation_probability = 0.2, num_mutations = 10, num_random_solutions_to_keep = 10, start_population = []):
        """
        num_mates describes how many times we do a random crossover between solutions in each generation
        """
        cdef list scenes, population, new_pop, scores, scores2, bad_population_to_survive
        cdef float start_time
        cdef int i, j, best_score
        cdef n1, n2, best_candidate
        cdef dict sol_score
    
        population = []
        start_time = time()
        
                    
        if start_population:
            population = start_population
        else:
            for i in range(population_size):
                scenes = self.problem.scenes[:]
                shuffle(scenes)
                population.append(Solution(self.problem, scenes))
            
        for generation in range(num_generations):
            new_pop = []
            # Crossover step
            for i in range(num_mates):
                shuffle(population)
                for j in range(int(len(population)/2)):
                    n1, n2 = self.crossover(population[j*2], population[j*2+1], mutation_probability)
                    new_pop += [n1, n2]
            population += new_pop
            new_pop = []
            # Mutation step
            for sol in population:
                if random() < mutation_probability:
                    new_pop.append(self.mutation(sol, num_mutations))
            # Add mutated solutions
            population += new_pop
            sol_scores = {sol: sol.compute_cost() for sol in population}
            scores = list(sol_scores.values())
            scores.sort()
            bad_population_to_survive = [sol for sol in population if sol_scores[sol] >= scores[min(len(population)-1,population_size-1)]]
            population = [sol for sol in population if sol_scores[sol] <= scores[min(len(population)-1,population_size-1)]]
            while len(population) > population_size:
                for sol in population:
                    if sol_scores[sol] == scores[min(len(population)-1,population_size-1)]:
                        population.remove(sol)
                        break
            population += bad_population_to_survive[:num_random_solutions_to_keep] # to keep the population more diverse, we keep a number of candidates that would otherwise die off
            scores2 = []
            for sol in population:
                scores2.append(sol_scores[sol])
            print('Generation %i, best score: %i' % (generation, min(scores)))
        
        best_candidate = population[0]
        best_score = best_candidate.compute_cost()
        for sol in population:
            if sol.compute_cost() < best_score:
                best_candidate = sol
                best_score = best_candidate.compute_cost()

        print('Best objective: '+str(best_candidate.compute_cost()))
        print('Location cost: '+str(best_candidate.location_cost()))
        print('Actor cost: '+str(best_candidate.actor_standby_cost()))
        print("Runtime: %d seconds" % (time()-start_time))
        return best_candidate