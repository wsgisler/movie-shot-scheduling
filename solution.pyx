from objects import *
            
cdef class Solution:

    cdef problem, sequence

    def __init__(self, prob, seq):
        self.problem = prob
        self.sequence = seq
        
    cpdef set_sequence(self, i, sc):
        self.sequence[i] = sc
    
    cpdef get_sequence(self, i):
        return self.sequence[i]
        
    cpdef get_num_scenes(self):
        return len(self.sequence)

    cpdef remove_and_reinsert(self, remove_pos, num_elements, insert_pos):
        cdef list pre, elms, post, temp
        pre = self.sequence[:remove_pos]
        elms = self.sequence[remove_pos:remove_pos+num_elements]
        post = self.sequence[remove_pos+num_elements:]
        temp = pre+post
        pre = temp[:insert_pos]
        post = temp[insert_pos:]
        self.sequence = pre+elms+post
        
    cpdef copy(self):
        return Solution(self.problem, [sc for sc in self.sequence])
        
    cpdef get_hash(self):
        return '_'.join([str(sc.id) for sc in self.sequence])
        
    cpdef int compute_cost(self):
        cdef int pc, asc, lc
        pc = self.precedence_cost()
        if pc > 1000:
            return pc
        asc = self.actor_standby_cost()
        lc = self.location_cost()
        return pc + asc + lc
        
    cpdef int precedence_cost(self):
        cdef int c
        c = 0
        for pc in self.problem.precedence_constraints:
            if self.sequence.index(pc.first) > self.sequence.index(pc.second):
                c += 1000000
        return c
        
    cpdef int actor_standby_cost(self):
        cdef int c, time, first_appearance, last_appearance
        cdef ac, scene
        c = 0
        time = 0
        for ac in self.problem.actors:
            first_appearance = 1000000
            last_appearance = 0
            for scene in self.sequence:
                if ac in scene.actors:
                    first_appearance = min(first_appearance, time)
                    last_appearance = time + scene.duration
                time += scene.duration
            c += (last_appearance - first_appearance)*ac.cost-sum([sc.duration for sc in self.problem.scenes if ac in sc.actors])*ac.cost
        return c
            
    cpdef int location_cost(self):
        cdef dict times_used
        cdef int i
        cdef sc, last_loc, loc
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
    