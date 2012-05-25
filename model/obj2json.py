# convert .obj file to JSON

try:
  import json
except ImportError:
  import simplejson as json


class ModelData:
  def __init__(self):
    self._obj = []
    self._position = []
    self._texCoord = []
    self._index = []
    self._list = []

  def toJSON(self):
    self.endGroup()
    return json.dumps(self._obj)

  def startGroup(self):
    self.endGroup()
    self._index = []
    self._list = []

  def endGroup(self):
    hasNothing = True
    position = []
    texCoord = []

    for (iv, ivt) in self._list:
      hasNothing = False
      position += self._position[iv]
      texCoord += self._texCoord[ivt]

    if hasNothing:
      return
    self._obj.append({
      'position': position,
      'texCoord': texCoord,
      'index': self._index
    })

  def addPosition(self, x, y, z):
    self._position.append((x, y, z))

  def addTexCoord(self, s, t):
    self._texCoord.append((s, t))

  def addFace(self, *v):
    for (iv, ivt) in v:
      if (iv, ivt) in self._list:
        idx = self._list.index((iv, ivt))
      else:
        self._list.append((iv, ivt))
        idx = len(self._list) - 1
      self._index.append(idx)


def main():
  filename = raw_input('filename: ')
  try:
    file = open(filename)
  except IOError:
    print 'failed open file "' + filename + '"'
    exit()

  data = ModelData()
  reachedLastVertex = True

  for line in file:
    word = line.split(' ')
    if word[0] == 'g':
      reachedLastVertex = False
      data.startGroup()
    elif word[0] == 'v':
      if reachedLastVertex:
        reachedLastVertex = False
        data.startGroup()
      apply(data.addPosition, preTransform(list(float(s) for s in word[1:])))
    elif word[0] == 'vt':
      reachedLastVertex = True
      apply(data.addTexCoord, list(float(s) for s in word[1:]))
    elif word[0] == 'vn':
      reachedLastVertex = True
      # ?
    elif word[0] == 'f':
      reachedLastVertex = True
      apply(data.addFace, list(vertex(s) for s in word[1:]))
    else:
      pass

  file.close()
  file = open(filename + '.json', 'w')
  file.write(data.toJSON())
  file.close()

  print 'Done!'


def vertex(str):
  return tuple(int(i) - 1 for i in str.split('/'))

def preTransform(list):
  return [
    list[0] / 20 + 0.5,
    -list[2] / 20 + 0.5,
    list[1] / 20 + 0.5
  ]

main()