'''lb.py
    Labyrinth maze generator
'''
from math import acos, pi, ceil, cos, sin, radians
import random
from sys import argv
from PIL import Image, ImageDraw
from time import time


bp_1 = """
<!doctype html>
<html>
   <body>
      <canvas
"""
bp_2 = """
      id = "Labyrinth"></canvas>
      <script>
         
var vertices = [
"""

bp_3 = """
];
         var canvas = document.getElementById('Labyrinth');
         var gl = canvas.getContext('experimental-webgl');
       
         var vertCode =
            'attribute vec2 coordinates;' +
            'void main(void) {' + ' gl_Position = vec4(coordinates,0.0, 1.0);' + '}';
         var vertShader = gl.createShader(gl.VERTEX_SHADER);
         gl.shaderSource(vertShader, vertCode);
         gl.compileShader(vertShader);
         var fragCode = 'void main(void) {' + 'gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);' + '}';
         var fragShader = gl.createShader(gl.FRAGMENT_SHADER);
         gl.shaderSource(fragShader, fragCode);
         gl.compileShader(fragShader);
         var shaderProgram = gl.createProgram();
         gl.attachShader(shaderProgram, vertShader);
         gl.attachShader(shaderProgram, fragShader);
         gl.linkProgram(shaderProgram);
         gl.useProgram(shaderProgram);
         gl.enable(gl.DEPTH_TEST);
         gl.viewport(0,0,canvas.width,canvas.height);
         gl.clearColor(1.0, 1.0, 1.0, 1.0);
         gl.clear(gl.COLOR_BUFFER_BIT);
        
         NumberofVerts = 
"""
bp_4 = """;
var numToDraw = 0;
         var n = 0;
         window.onload = function start() {
            lloop();
         }
         function lloop () {
            requestAnimationFrame(lloop);
            draw();
         }
         function draw(){
            n += 1;
            numToDraw += 
"""
bp_5 = """*n;
            if (numToDraw > NumberofVerts){
               numToDraw = NumberofVerts;
            }   
            gl.clear(gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT);
            var my_vertex_buffer = gl.createBuffer();
            gl.bindBuffer(gl.ARRAY_BUFFER, my_vertex_buffer);
            gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW);
            coord = gl.getAttribLocation(shaderProgram, "coordinates");
            gl.enableVertexAttribArray(coord);
            gl.vertexAttribPointer(coord, 2, gl.FLOAT, false, 0, 0);
            gl.useProgram(shaderProgram);
            gl.drawArrays(gl.LINES, 0, numToDraw);
            console.log("WAA");
            if (numToDraw == NumberofVerts){
               numToDraw = 0;
               n = 0;
               gl.clearColor(Math.random(), Math.random(), Math.random(), 1.0);
            }
         }
      </script>
   </body>
</html>
"""



class Labyrinth:
    def __init__(self, n, d):
        self.n = n                 # number of rings
        self.cuts = d            # number of sections in smallest ring
        self.x = 20 * n            # size of image's X axis
        self.y = 20 * n            # size of image's Y axis
        self.par = 0            # number of nodes created
        self.delta = 360.0/d    # angle of a section between nodes
        self.rep = [self.init_cells(i) for i in range(1,n)]
        # list containing nodes
        self.flat = [item for sublist in self.rep for item in sublist]
        # self.rep flattened
        self.ring_sizes = [len(i) for i in self.rep]
        self.graph = []
        #list containing unsorted edges
        self.order = []
        self.init_edges(self.rep, self.par)
        self.kruskal()

    def init_cells(self, ring):
        '''    arg:        ring:int
            returns     rv:list
            Determine size of ring and return list of unique ints
            with respect to other rings.
        '''
        ang = (180.0*acos((2.0*(ring**2)-1.0)/(2.0*ring**2)))/pi
        if ang <= self.delta / 2:
            self.cuts = self.cuts * 2
            self.delta = ang
        rv = [i+self.par for i in range(self.cuts)]
        self.par = self.par + self.cuts
        return rv

    def cart(self, n, translator):
        '''    args:         n:int, translator:list
            returns:    x:int, y:int
            Takes an int and returns its x,y coord with respect to the
            translator list.
        '''
        r = 1
        for i in range(len(translator)):
            if n >= translator[i]:
                r = r + 1
                n = n - translator[i]
            else:
                break
        r = r*1.0
        t = (n*1.0)/translator[i] * 360
        x = (r+0.5) * cos(radians(t+10))
        y = (r+0.5) * sin(radians(t+10))
        return x*10, y*10

    def find(self, parent, i):
        if parent[i] == i:
            return i
        return self.find(parent, parent[i])

    def union(self, parent, rank, x, y):
        xroot = self.find(parent, x)
        yroot = self.find(parent, y)

        if rank[xroot] < rank[yroot]:
            parent[xroot] = yroot
        elif rank[xroot] > rank[yroot]:
            parent[yroot] = xroot
        else :
            parent[yroot] = xroot
            rank[xroot] += 1

    def kruskal(self):
        result = [] # list containing the final MST

        i = 0 # An index variable, used for sorted edges
        e = 0 # An index variable, used for result[]
        self.graph = sorted(self.graph,key=lambda item: item[2])

        parent  =   [i for i in range(self.par)]
        rank    =   [0 for i in range(self.par)]



        while e < self.par-1 :

            if i >= len(self.graph):
                break
            u,v,w = self.graph[i]
            i = i+1
            x = self.find(parent, u)
            y = self.find(parent ,v)

            if x != y:
                e = e+1
                result.append([u,v,w])
                self.union(parent, rank, x, y)

        for u,v,weight in result:
             self.order.append((u, v))


    def init_edges(self, form, size):
        ''' args:        form:list, size:int
            returns:    -
            Creates possible edges from list of nodes
        '''
        for i in range(len(form)):
            if i < len(form)-1:
                if len(form[i+1]) > len(form[i]): # if next ring is bi-sected
                    for j in range(len(form[i])):
                        self.graph.append([form[i][j], form[i+1][j*2], random.randint(0,20)])
                else:
                    for j in range(len(form[i])):
                        self.graph.append([form[i][j], form[i+1][j], random.randint(0,20)])
            for j in range(len(form[i])):
                self.graph.append([form[i][j], form[i][(j+1) % len(form[i])], random.randint(0,5)])

    def img(self):
        ''' draw!!
        '''
        image = Image.new("RGB", (self.x, self.y),(255,255,255))
        draw = ImageDraw.Draw(image)
        for mv in self.order:
            (a, b) = mv
            x1, y1 = self.cart(a,self.ring_sizes)
            x2, y2 = self.cart(b,self.ring_sizes)
            #print ("({},{}) --> ({},{})").format(x1, y1, x2, y2)
            draw.line((x1+(self.x/2),y1+(self.y/2),x2+(self.x/2),y2+(self.y/2)), fill=(160,82,45), width=1)

        del draw
        image.save('{}.png'.format(argv[1]))
        print("Total nodes:      {}".format(self.par))
        print("Dimensions:       {}x{}".format(self.x, self.y))
        print("Created:          \"{}.png\"".format(argv[1]))

    def gif(self):
        ''' draw!!
        '''       
        frames = []
        dur = []
        delta = int(len(self.order)//self.n)
        print(delta)
        for i in range(delta):
            print(i)
            dur.append(2)
            image = Image.new("RGB", (self.x//3, self.y//3),(160,82,45))
            draw = ImageDraw.Draw(image)
            limit = min(delta*i, len(self.order))

            mv =  0
            while mv < limit:
                (a, b) = self.order[mv]
                x1, y1 = self.cart(a,self.ring_sizes)
                x2, y2 = self.cart(b,self.ring_sizes)
                #print ("({},{}) --> ({},{})").format(x1, y1, x2, y2)
                draw.line(((x1/3)+(self.x/6),(y1/3)+(self.y/6),(x2/3)+(self.x/6),(y2/3)+(self.y/6)), fill=(255,255,0), width=1)
                mv+=1
            del draw
            frames.append(image)

        dur[-1] = 150
        frames[0].save('{}.gif'.format(argv[1]), save_all=True, append_images=frames[1:], optimize=True, duration=dur,loop=0)
        print("Total nodes:      {}".format(self.par))
        print("Dimensions:       {}x{}".format(self.x, self.y))
        print("Created:          \"{}.gif\"".format(argv[1]))

    def wgl(self):

        html_file = open('{}.html'.format(argv[1]), 'w')
        html_file.write(bp_1)
        html_file.write("width = \"{}\" height = \"{}\"".format(self.x, self.y))
        html_file.write(bp_2)
        for mv in self.order:
            (a, b) = mv
            x1, y1 = self.cart(a,self.ring_sizes)
            x2, y2 = self.cart(b,self.ring_sizes)
            html_file.write(str(x1/self.x * 2)+','+str(y1/self.x * 2)+','+str(x2/self.x * 2)+','+str(y2/self.x * 2)+',\n')

        html_file.write(bp_3)
        r=len(self.order)*2
        html_file.write(str(r))
        html_file.write(bp_4)
        html_file.write(str(self.n))
        html_file.write(bp_5)
        html_file.close()



if __name__ == '__main__':
    s = time()
    random.seed("L-A-B-Y-R-I-N-T-H")
    l = Labyrinth(int(argv[2]), int(argv[3]))
    #l.img()
    #e = time()
    #print("Time Elapsed:     [{}]".format(e-s))
    if(len(argv)>4):
        if (argv[4] == "webgl"):
            l.wgl()
        elif (argv[4] == "png"):
            l.img()
        elif (argv[4] == "gif"):
            l.gif()

