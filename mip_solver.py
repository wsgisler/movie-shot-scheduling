from solvers import Solver
from docplex.mp.model import Model
from reader import Solution
from random import random

class MipSolver(Solver):

    def __get_model(self):
        
        m = Model()
        
        scenes = self.problem.scenes
        actors = self.problem.actors
        locations = self.problem.locations
        positions = [sc.id for sc in scenes]
        max_duration = sum(sc.duration for sc in scenes)
        
        # Variable declaration
        self.x = {(s,p): m.binary_var(name = 'x_'+str(s.id)+'_'+str(p)) for s in scenes for p in positions}
        open_location = {(l,p): m.continuous_var(lb = 0, ub = 1) if p != -1 else 0  for l in locations for p in positions+[-1]}
        first_appearance = {a: m.continuous_var(lb = 0, ub = max_duration) for a in actors}
        last_appearance = {a: m.continuous_var(lb = 0, ub = max_duration) for a in actors}
        start_time = {p: m.continuous_var(lb = 0, ub = max_duration) if p != -1 else 0 for p in positions+[-1]}
        end_time = {p: start_time[p+1] if p != positions[-1] else max_duration for p in positions}
        
        # Constraints
        # C1: Every scene is in exactly one position
        for s in scenes:
            m.add(m.sum(self.x[(s,p)] for p in positions) == 1)
        # C2: Every position has exactly one scene
        for p in positions:
            m.add(m.sum(self.x[(s,p)] for s in scenes) == 1)
        # C3: precedence constraints:
        for pc in self.problem.precedence_constraints:
            m.add(m.sum(self.x[(pc.first,p)]*p for p in positions) <= m.sum(self.x[(pc.second,p)]*p for p in positions))
        # C4: Venue is opened
        for l in locations:
            for p in positions:
                m.add(open_location[(l,p)] >= m.sum(self.x[(s,p)] for s in l.scenes) - open_location[(l,p-1)])
        # C5: Time for each position
        m.add(start_time[0] == 0)
        for p in positions[1:]:
            m.add(start_time[p] == start_time[p-1] + m.sum(self.x[(s,p-1)]*s.duration for s in scenes))
        # C6: First and last appearance of each actor
        for a in actors:
            for p in positions:
                m.add(first_appearance[a] <= start_time[p] + (1-m.sum(self.x[(s,p)] for s in a.scenes))*max_duration)
                m.add(last_appearance[a] >= end_time[p] - (1-m.sum(self.x[(s,p)] for s in a.scenes))*max_duration)
                
        # Objective
        location_cost = m.sum((m.sum(open_location[(l,p)] for p in positions)-1)*l.cost for l in locations)
        actor_standby_cost = m.sum((last_appearance[a]-first_appearance[a]-sum(s.duration for s in a.scenes))*a.cost for a in actors)
        m.minimize(location_cost + actor_standby_cost)
        return m
        
    def __interpret_solution(self):
        seq = [None for s in self.problem.scenes]
        sol_bins = []
        for s in self.problem.scenes:
            for p,s2 in enumerate(self.problem.scenes):
                if self.x[(s,p)].solution_value > 0.5:
                    seq[p] = s
                    sol_bins.append(self.x[(s,p)])
        solution = Solution(self.problem, seq)
        print('Best objective: '+str(solution.compute_cost()))
        print('Location cost: '+str(solution.location_cost()))
        print('Actor cost: '+str(solution.actor_standby_cost()))
        score = solution.compute_cost()
        solution.write('solution/'+str(score)+'-optimized-schedule.mss')
        return solution, sol_bins

    def solve(self):
        m = self.__get_model()
        m.solve(log_output = True)
        solution, sol_bins = self.__interpret_solution()
        return solution
        
    def lns_solve(self, num_iterations = 100, initial_time_limit = 100, iteration_time_limit = 20, relax_percentage = 0.36, start_path = ''):
        m = self.__get_model()
        rc = []
        if start_path:
            f = open(start_path,'r')
            sss = f.read()
            sss = sss.replace(' ','')
            sss = sss.replace('[','')
            sss = sss.replace(']','')
            tokens = sss.split(',')
            for p,tok in enumerate(tokens):
                rc.append(m.add(self.x[(self.problem.scenes[int(tok)], p)] == 1))
        m.parameters.timelimit = initial_time_limit
        m.solve(log_output = True)
        if start_path:
            m.remove_constraints(rc)
        for i in range(num_iterations):
            solution, sol_bins = self.__interpret_solution()
            lns_constraints = [] 
            for bin in sol_bins:
                if random() > relax_percentage:
                    lns_constraints.append(m.add(bin == 1))
            m.parameters.timelimit = iteration_time_limit
            m.solve(log_output = True)
            m.remove_constraints(lns_constraints)
        solution, sol_bins = self.__interpret_solution()
        return solution