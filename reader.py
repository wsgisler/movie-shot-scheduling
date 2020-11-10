from math import ceil
from objects import *

class Reader:

    def __init__(self):
        pass
        
    def read(self, path):
        self.actors = []
        self.scenes = []
        self.locations = []
        self.precedence_constraints = []
        f = open(path)
        content = f.read()
        content = content.replace(';',''); content = content.replace('[|','['); content = content.replace('|]',']'); content = content.replace('|',',')
        self.ActorCost = []; self.LocationCost = []; self.SceneDuration = []; self.SceneLocation = []; self.Presence = []; self.Precedences = []
        # Presence, ActorCost, LocationCost, SceneLocation, Precedences
        exec(content+'\nself.ActorCost = ActorCost\nself.LocationCost = LocationCost\nself.SceneLocation = SceneLocation\nself.Presence = Presence\nself.Precedences = Precedences\nself.SceneDuration = SceneDuration')
        for i, ac in enumerate(self.ActorCost):
            self.actors.append(Actor(i, ac))
        for i, lc in enumerate(self.LocationCost):
            self.locations.append(Location(i, lc))
        for i, sd in enumerate(self.SceneDuration):
            lo = self.locations[self.SceneLocation[i]]
            self.scenes.append(Scene(i, sd, lo))
            #self.scenes.append(Scene(i, 1, lo))
        for i, pr in enumerate(self.Presence):
            sc = self.scenes[i%len(self.scenes)]
            ac = self.actors[int(ceil((i+1)/len(self.scenes)))-1]
            if pr == 1: ac.add_scene(sc)
        for i in range(int(len(self.Precedences)/2)):
            sc1 = self.scenes[self.Precedences[2*i]]
            sc2 = self.scenes[self.Precedences[2*i+1]]
            self.precedence_constraints.append(PrecedenceConstraint(sc1, sc2))
        return Problem(self.actors, self.scenes, self.locations, self.precedence_constraints)
            
class Problem:

    def __init__(self, actors, scenes, locations, precedence_constraints, name = ''):
        self.actors = actors
        self.scenes = scenes
        self.locations = locations
        self.precedence_constraints = precedence_constraints
        self.name = name
            
class Solution:

    def __init__(self, problem, sequence):
        self.problem = problem
        self.sequence = sequence
        
    def copy(self):
        return Solution(self.problem, [sc for sc in self.sequence])
        
    def get_hash(self):
        return '_'.join([str(sc.id) for sc in self.sequence])
        
    def compute_cost(self):
        pc = self.precedence_cost()
        if pc > 1000:
            return pc
        return pc + self.actor_standby_cost() + self.location_cost()
        
    def precedence_cost(self):
        c = 0
        for pc in self.problem.precedence_constraints:
            if self.sequence.index(pc.first) > self.sequence.index(pc.second):
                c += 100000000000
        return c
        
    def actor_standby_cost(self):
        c = 0
        time = 0
        for ac in self.problem.actors:
            first_appearance = 1000000000000
            last_appearance = 0
            for scene in self.sequence:
                if ac in scene.actors:
                    first_appearance = min(first_appearance, time)
                    last_appearance = time + scene.duration
                time += scene.duration
            c += (last_appearance - first_appearance)*ac.cost-sum([sc.duration for sc in self.problem.scenes if ac in sc.actors])*ac.cost
        return c
            
    def location_cost(self):
        times_used = {loc:0 for loc in self.problem.locations}
        last_loc = -1
        for i, sc in enumerate(self.sequence):
            loc = sc.location
            if last_loc != loc:
                last_loc = loc
                times_used[loc] += 1
        return sum([loc.cost * max(0, times_used[loc]-1) for loc in self.problem.locations])
        
    def visualize(self, path = 'solution.html'):
        f = open(path, 'w')
        f.write('<html><body><table border="1"><tr><td>Time</td>')
        for i in range(sum([sc.duration for sc in self.problem.scenes])):
            f.write('<td>'+str(i)+'</td>')
        f.write('</tr>')
        f.write('<tr><td>Scene</td>')
        for scene in self.sequence:
            for i in range(scene.duration):
                f.write('<td>'+str(scene.id)+'</td>')
        f.write('</tr>')
        for ac in self.problem.actors:
            f.write('<tr><td>Actor '+str(ac.id)+'</td>')
            for scene in self.sequence:
                if ac in scene.actors:
                    for i in range(scene.duration):
                        f.write('<td>1</td>')
                else:
                    for i in range(scene.duration):
                        f.write('<td></td>')
            f.write('</tr>')
        for lo in self.problem.locations:
            f.write('<tr><td>Location '+str(lo.id)+'</td>')
            for scene in self.sequence:
                if lo == scene.location:
                    for i in range(scene.duration):
                        f.write('<td>1</td>')
                else:
                    for i in range(scene.duration):
                        f.write('<td></td>')
        f.write('</table></body></html>')
        f.close()
        
    def write(self, path):
        f = open(path, 'w')
        f.write('['+(', '.join([str(sc.id) for sc in self.sequence]))+']')
    