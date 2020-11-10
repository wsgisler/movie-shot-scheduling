from solution import Solution
from time import time
from random import random, shuffle, randint, choice
from math import exp
from multiprocessing import Process, Queue
import os, subprocess

cdef class SimulatedAnnealingSolver:
    cdef problem

    def __init__(self, problem):
        self.problem = problem

    cdef propose_neighbor(self, current_solution):
        cdef list ss
        cdef temp, next, best_next
        cdef float rnum
        cdef int best_score, pos, num_elements, i, next_score, num_attempts
        rnum = random()
        next = current_solution.copy()
        if rnum < 0:#0.2:
            # Strategy: randomly select two scenes and swap their position
            ss = [i for i in range(current_solution.get_num_scenes())]
            shuffle(ss)
            temp = next.get_sequence(ss[0])
            next.set_sequence(ss[0], next.get_sequence(ss[1]))
            next.set_sequence(ss[1], temp)
            return next
        else:
            if rnum < 0.5:
                num_elements = 2
            elif rnum < 0.7:
                num_elements = 3
            elif rnum < 0.8:
                num_elements = 1
            elif rnum < 1.1:
                num_elements = 4
            # Randomly remove a set of scenes and reinsert them in the same order. Test a random choice of positions to find the best possible position
            next = current_solution.copy()
            best_score = 1410065408
            num_attempts = 6
            num_elements = 2
            pos = randint(0, next.get_num_scenes()-num_elements)
            for i in range(0, num_attempts):
                next = current_solution.copy()
                next.remove_and_reinsert(pos, num_elements, randint(0, next.get_num_scenes()-num_elements))
                next_score = next.compute_cost()
                if next_score < best_score:
                    best_score = next_score
                    next_best = next
            return next_best
            
        
    cdef accept_neighbor(self, current, neighbor, current_score, neighbor_score, temperature):
        cdef float enumber, p
        enumber = (current_score-neighbor_score)/temperature
        try:
            p = exp(enumber)
        except:
            print('neighbor score: '+str(neighbor_score))
            print('current score: '+str(current_score))
            print(enumber)
            if enumber > 0:
                p = 1
            if enumber < -10:
                p = 0
        rand = random()
        next = current
        if(rand < p):
            next = neighbor
            current_score = neighbor_score
        return next.copy(), current_score
        
    cpdef pool_solve(self, time_limit, start_temperature_min, start_temperature_max, thread_num = -1):
        cdef starting_solution, start_solution, sc, random_initial_solution, optimized_schedule, best_solution, f, this_sol
        cdef int best_score, score
        cdef list solution_pool, scc, tokens
        cdef set solution_pool_hash
        cdef float cooling_rate, last_temperature
        cdef int number_iterations_per_temperature
        cdef str pret, sss, sol, tok
        
        pret = 'Thread '+str(thread_num)+': ' if thread_num >= 0 else ''
        
        starting_solution = Solution(self.problem, self.problem.scenes[:])

        solution_pool = []
        solution_pool_hash = set()
        best_score = 100000000
        while True:
            best_score = 100000000
            for sol in os.listdir('./solution/'):
                if '.mss' in sol:
                    f = open('./solution/'+sol,'r')
                    sss = f.read()
                    sss = sss.replace(' ','')
                    sss = sss.replace('[','')
                    sss = sss.replace(']','')
                    tokens = sss.split(',')
                    scc = []
                    for tok in tokens:
                        scc.append(self.problem.scenes[int(tok)])
                    this_sol = Solution(self.problem, scc)
                    solution_pool.append(this_sol)
                    solution_pool_hash.add(this_sol.get_hash())
                    if this_sol.compute_cost() < best_score:
                        best_solution = this_sol
                        best_score = this_sol.compute_cost()
            sc = self.problem.scenes[:]
            shuffle(sc)
            random_initial_solution = Solution(self.problem, sc)
            start_temperature = randint(start_temperature_min,start_temperature_max)
            cooling_rate = 0.8+random()/6
            last_temperature = 1
            if start_temperature < 20:
                cooling_rate = 0.95
                last_temperature = 0.01
            number_iterations_per_temperature = randint(300, 2000)
            if len(solution_pool) == 0:
                start_solution = random_initial_solution
            elif random() < 0.5: # in 50% of cases, we start with the best solution we found
                start_solution = best_solution
                print(pret+'Start with current optimal solution')
            elif random() < 0.75: # in 25% of cases we start with a random solution from the solution pool
                start_solution = choice(solution_pool)
                print(pret+'Start with a previously found solution')
            else:
                start_solution = random_initial_solution
            optimized_schedule = self.solve(start_solution, start_temperature, last_temperature, cooling_rate, number_iterations_per_temperature, thread_num)
            score = optimized_schedule.compute_cost()
            optimized_schedule.write('solution/'+str(score)+'-optimized-schedule.mss')
            if optimized_schedule.get_hash() not in solution_pool_hash:
                solution_pool.append(optimized_schedule)
                solution_pool_hash.add(optimized_schedule.get_hash())
            if score < best_score:
                best_solution = optimized_schedule

    cpdef solve(self, starting_solution, start_temperature, t_min, alpha, beta, thread_num = -1):
        cdef sol, best_candidate, current_candidate, next_candidate
        cdef int total_evaluated, total_improvements, best_score, current_score, counter, next_score
        cdef float start_time, temperature
        cdef str pret 
        
        pret = 'Thread '+str(thread_num)+': ' if thread_num >= 0 else ''
    
        sol = starting_solution.copy()
        
        start_time = time()
        best_candidate = sol.copy()
        total_evaluated = 0
        total_improvements = 0
        best_score = 10000000
        current_candidate = best_candidate.copy()
        next_candidate = None
        temperature = start_temperature
        current_score = current_candidate.compute_cost()
        best_score = best_candidate.compute_cost()
        counter = 0
        print(pret+"Initial score: %f" % best_score)
        print(pret+"Initial temperature: %f" % temperature)
        while(temperature > t_min and best_score != 0):
            counter += 1
            next_candidate = self.propose_neighbor(current_candidate)
            next_score = next_candidate.compute_cost()
            current_candidate, current_score = self.accept_neighbor(current_candidate, next_candidate, current_score, next_score, temperature)
            total_evaluated += 1
            if(current_score < best_score):
                total_improvements += 1
                counter = 0
                best_candidate = current_candidate.copy()
                best_score = current_score
            if(counter == beta):
                counter = 0
                temperature = temperature*alpha
                print(pret+"New temperature: %f, Improvements: %d, Best score: %f, Current score: %f" % (temperature, total_improvements, best_score, current_score));

        print(pret+'Best objective: '+str(best_candidate.compute_cost()))
        print(pret+'Location cost: '+str(best_candidate.location_cost()))
        print(pret+'Actor cost: '+str(best_candidate.actor_standby_cost()))
        print(pret+"Runtime: %d seconds" % (time()-start_time))
        print(pret+"Schedules evaluated per second: %f" % (total_evaluated/(time()-start_time)))
        print(pret+"Number of improving moves: %d" % total_improvements)
        return best_candidate
        
    cpdef multi_process_pool_solve(self, num_workers = 8, start_temperature_min = 2, start_temperature_max = 300):
        cdef list processes
        processes = [Process(target = self.pool_solve, args = (0, start_temperature_min, start_temperature_max, w)) for w in range(num_workers)]
        for w in range(num_workers):
            processes[w].start()
        for w in range(num_workers):
            processes[w].join()
            