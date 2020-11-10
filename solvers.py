from reader import Solution
from itertools import permutations
from time import time

class Solver:

    def __init__(self, problem):
        self.problem = problem
        
    def solve(self):
        pass
        
class BruteForceSolver(Solver):
    
    def solve(self):
        st = time()
        p = self.problem
        best_sol = None
        best_obj = 10000000000

        counter = 0
        for perm in permutations(p.scenes):
            counter += 1
            sol = Solution(p, perm)
            obj = sol.compute_cost()
            if obj < best_obj:
                print('Solution '+str(counter))
                best_sol = sol
                best_obj = obj
                print('New best: '+str(best_obj))
        print('Time spent: '+str(time()-st)+' seconds')
        print('Best objective: '+str(best_sol.compute_cost()))
        return best_sol