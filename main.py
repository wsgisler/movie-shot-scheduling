from reader import Reader, Solution
from solvers import BruteForceSolver
from mip_solver import MipSolver
from cp_optimizer_solver import CpOptimizerSolver
from sa_solver import SimulatedAnnealingSolver

# name of the problem instance
problem_name = 'mss300'

# Read data and create a problem instance
reader = Reader()
p = reader.read('instances/'problem_name+'.dzn')

# Use a solver to optimize the overall objective
#solution = BruteForceSolver(p).solve()
#solution = CpOptimizerSolver(p).solve(time_limit = 72000)
#solution = SimulatedAnnealingSolver(p).pool_solve(0, [2, 300])
solution = SimulatedAnnealingSolver(p).multi_process_pool_solve(8, 1, 15)
#solution = MipSolver(p).solve()
#solution = MipSolver(p).lns_solve(num_iterations = 100, initial_time_limit = 100, iteration_time_limit = 10, relax_percentage = 0.1, start_path = 'solution/1.mss')

# Visualize solution
solution.visualize(path = 'solution/solution.html')

solution.write('solution/' + problem_name + '.mss')