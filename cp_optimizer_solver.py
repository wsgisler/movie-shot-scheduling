from solvers import Solver
from docplex.cp.model import CpoModel
from reader import Solution

class CpOptimizerSolver(Solver):

    def solve(self, time_limit = 10):
        m = CpoModel()
        MAX_T = sum(sc.duration for sc in self.problem.scenes)
        
        interval_vars = [m.interval_var(start = (0, MAX_T), end = (0, MAX_T), length = sc.duration) for sc in self.problem.scenes]
        
        # Precedence constraints
        for pc in self.problem.precedence_constraints:
            m.add(m.end_of(interval_vars[pc.first.id]) <= m.start_of(interval_vars[pc.second.id]))
            
        # No overlap and sequence
        seq = m.sequence_var(interval_vars, types = [sc.location.id for sc in self.problem.scenes])
        m.add(m.no_overlap(seq))
        
        # Actor cost
        actor_standby_cost = 0
        for actor in self.problem.actors:
            actor_present = m.interval_var(start = (0, MAX_T), end = (0, MAX_T))
            for sc in actor.scenes:
                m.add(m.start_of(actor_present) <= m.start_of(interval_vars[sc.id]))
                m.add(m.end_of(actor_present) >= m.end_of(interval_vars[sc.id]))
            actor_standby_cost += (m.end_of(actor_present)-m.start_of(actor_present)-sum(sc.duration for sc in actor.scenes))*actor.cost
            
        # Location cost
        location_used = {loc: [] for loc in self.problem.locations}
        for sc in self.problem.scenes:
            location_used[sc.location].append(m.type_of_next(seq, interval_vars[sc.id], lastValue = -1) != sc.location.id)
        location_cost = m.sum((m.sum(location_used[loc])-1)*loc.cost for loc in self.problem.locations)
        
        # Solve
        m.minimize(actor_standby_cost + location_cost)
        cpsol = m.solve(TimeLimit = time_limit)
        
        # Retrieve solution
        sol = list()
        for sc in self.problem.scenes:
            sol.append((sc, cpsol.get_value(interval_vars[sc.id])[0]))
        sol = sorted(sol, key = lambda a: a[1])
        seq = [i[0] for i in sol]
        
        solution = Solution(self.problem, seq)
        print('Best objective: '+str(solution.compute_cost()))
        print('Location cost: '+str(solution.location_cost()))
        print('Actor cost: '+str(solution.actor_standby_cost()))
        return solution