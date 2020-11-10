class Actor:
    
    def __init__(self, id, cost):
        self.id = id
        self.cost = cost
        self.scenes = []
        
    def add_scene(self, scene):
        self.scenes.append(scene)
        scene.actors.append(self)
        
class Location:
    
    def __init__(self, id, cost):
        self.id = id
        self.cost = cost
        self.scenes = []
        
class Scene:
    
    def __init__(self, id, duration, location):
        self.id = id
        self.duration = duration
        self.location = location
        location.scenes.append(self)
        self.actors = []
        
    def add_actor(self, actor):
        self.actors.append(actor)
        actor.scenes.append(self)
        
class PrecedenceConstraint:

    def __init__(self, first, second):
        self.first = first
        self.second = second