
mesh = controls = scene = camera = renderer = null

initScene = ->
  renderer = new THREE.WebGLRenderer({ antialias: true })
  renderer.setSize( window.innerWidth, window.innerHeight )
  renderer.shadowMapEnabled = true
  renderer.shadowMapSoft = true
  renderer.setClearColor 0xaaaaaa
  document.body.appendChild( renderer.domElement )

  scene = new CANNON.World()
  scene.gravity.set(0, -90, 0)
  scene.broadphase = new CANNON.NaiveBroadphase()

  camera = new THREE.PerspectiveCamera(35, window.innerWidth / window.innerHeight, 1, 1000 )
  camera.position.set( 60, 50, 60 )
  camera.lookAt( scene.position )
  scene.add( camera )

  controls = new THREE.OrbitControls(@camera, @renderer.domElement)

  # Light
  light = new THREE.DirectionalLight( 0xFFFFFF )
  light.position.set( 20, 40, -20 )
  light.target.position.copy( scene.position )
  light.castShadow = true
  light.shadowCameraLeft = -60
  light.shadowCameraTop = -60
  light.shadowCameraRight = 60
  light.shadowCameraBottom = 60
  light.shadowCameraNear = 20
  light.shadowCameraFar = 200
  light.shadowBias = -.0001
  light.shadowMapWidth = light.shadowMapHeight = 2048
  light.shadowDarkness = .7
  scene.add( light )

  light = new THREE.DirectionalLight( 0xFFFFFF )
  light.position.set( -20, 40, 20 )
  light.target.position.copy( scene.position )
  light.castShadow = true
  light.shadowCameraLeft = -60
  light.shadowCameraTop = -60
  light.shadowCameraRight = 60
  light.shadowCameraBottom = 60
  light.shadowCameraNear = 20
  light.shadowCameraFar = 200
  light.shadowBias = -.0001
  light.shadowMapWidth = light.shadowMapHeight = 2048
  light.shadowDarkness = .7
  scene.add( light )

  light = new THREE.DirectionalLight( 0xFFFFFF )
  light.position.set( -20, 40, -20 )
  light.target.position.copy( scene.position )
  light.castShadow = true
  light.shadowCameraLeft = -60
  light.shadowCameraTop = -60
  light.shadowCameraRight = 60
  light.shadowCameraBottom = 60
  light.shadowCameraNear = 20
  light.shadowCameraFar = 200
  light.shadowBias = -.0001
  light.shadowMapWidth = light.shadowMapHeight = 2048
  light.shadowDarkness = .7
  scene.add( light )

  class Grid
    defaults:
      y: 0
      step: 2
      lines: 50

    material: Physijs.createMaterial(
      new THREE.MeshNormalMaterial( { transparent: true, opacity: 0.0 } ),
      .8,# high friction
      .3 # low restitution
    )

    constructor: (options) ->
      {@y, @step, @lines} = _.extend {}, @defaults, options
      @end = (@step * @lines) / 2
      @start = -@end
      @updateGrid()
      @updatePlane()

    updateGrid: ->
      line_material = new THREE.LineBasicMaterial( { color: 0x000000 } )
      line_geometry = new THREE.Geometry()
      for i in [0..@lines]
        line_geometry.vertices.push(
          new THREE.Vector3( @start, @floor, i * @step - @end ) )
        line_geometry.vertices.push(
          new THREE.Vector3( -@start, @floor, i * @step - @end ) )
        line_geometry.vertices.push(
          new THREE.Vector3( i * @step + @start, @floor, -@end ) )
        line_geometry.vertices.push(
          new THREE.Vector3( i * @step + @start, @floor,  @end ) )
      @grid = new THREE.Line( line_geometry, line_material, THREE.LinePieces )

    updatePlane: ->
      geometry = new THREE.CubeGeometry(@end*2, 1, @end*2)
      @plane = new Physijs.BoxMesh(geometry, @material, 0)
      @plane.receiveShadow = true

    addToScene: (scene) ->
      scene.add @plane
      scene.add @grid


  class Gene
    @random = (n)->
      Math.random() for [1..n]

  class Part
    expressGene: (gene, multiplier, offset) ->
      (multiplier * @genes[gene]) + offset
    constructor: (@genes) ->
      @mesh = @build()

  class Wheel extends Part
    outerRadius: =>
      @expressGene(0, 5, 0.5)
    innerRadius: =>
      @expressGene(1, 5, 0.5)
    thickness: =>
      @expressGene(2, 5, 0.3)
    velocity: =>
      if @genes[3] > 0.5 then 5 else -5

    expressGene: (gene, multiplier, offset) ->
      super gene, multiplier, offset

    constructor: (@genes, index, @parent, @position, @normal) ->
      @gene = @genes[index]
      super @genes

    forward: ->
      if @normal.y != 0
        @constraint.configureAngularMotor( 1, 1, 0, @velocity(), 2000 )
        @constraint.enableAngularMotor( 1 )
      else if @normal.z != 0
        @constraint.configureAngularMotor( 2, 1, 0, @velocity(), 2000 )
        @constraint.enableAngularMotor( 2 )
      else
        @constraint.configureAngularMotor( 3, 1, 0, @velocity(), 2000 )
        @constraint.enableAngularMotor( 3 )

    stop: ->
      if @normal.y != 0
        @constraint.disableAngularMotor( 1 )
      else if @normal.z != 0
        @constraint.disableAngularMotor( 2 )
      else
        @constraint.disableAngularMotor( 3 )

    material: Physijs.createMaterial(
      new THREE.MeshLambertMaterial({ map: THREE.ImageUtils.loadTexture( 'images/checker.gif' ) }),
      .8, .5)

    sign: (number) ->
      if number < 0 then -1 else 1

    build: ->
      wheel_geometry = new THREE.CylinderGeometry(
        @outerRadius(),
        @innerRadius(),
        @thickness(), 16 )
      mesh = new Physijs.CylinderMesh(
        wheel_geometry,
        @material,
        16
      )
      mesh.receiveShadow = true
      mesh.position.copy @position
      console.log 'before', mesh.matrix.toArray()
      # localNormal = mesh.worldToLocal(@normal).normalize()
      # mesh.updateMatrix()
      # mesh.translateOnAxis(@normal, @thickness()*3 )
      # mesh.updateMatrix()
      # mesh.lookAt(localNormal.clone().add(mesh.position))
      # mesh.rotation.z = Math.PI/2
      # mesh.updateMatrix()


      # if @normal.y == -1
      #   axis = new THREE.Vector3(1, 0, 0)
      #   mesh.rotateOnAxis(axis, Math.PI)
      # else if @normal.z == 1
      #   axis = new THREE.Vector3(1, 0, 0)
      #   mesh.rotateOnAxis(axis, Math.PI/2.0)
      # else if @normal.z == -1
      #   axis = new THREE.Vector3(1, 0, 0)
      #   mesh.rotateOnAxis(axis, -Math.PI/2.0)
      # else if @normal.x == 1
      #   axis = new THREE.Vector3(0, 0, 1)
      #   mesh.rotateOnAxis(axis, -Math.PI/2.0)
      # else if @normal.x == -1
      #   axis = new THREE.Vector3(0, 0, 1)
      #   mesh.rotateOnAxis(axis, Math.PI/2.0)
      # mesh.updateMatrix()
      console.log 'normal', @normal
      console.log 'after', mesh.matrix.toArray()
      console.log 'rotation', mesh.rotation
      mesh

    addToScene: (scene) ->
      scene.add @mesh

    setupConstraints: (scene) ->
      @constraint = new Physijs.DOFConstraint(@mesh, @mesh.position)
      scene.addConstraint @constraint
      @constraint.setAngularLowerLimit({ x: 0, y: 0, z: 0 })
      @constraint.setAngularUpperLimit({ x: 0, y: 0, z: 0 })
      @constraint.setLinearLowerLimit({ x: 0, y: 0, z: 0 })
      @constraint.setLinearUpperLimit({ x: 0, y: 0, z: 0 })

  class Body extends Part
    width: ->
      @expressGene(0, 15, 5)
    height: ->
      @expressGene(1, 5, 4)
    length: ->
      @expressGene(2, 10, 3)

    constructor: (@genes, @position) ->
      super @genes

    @material: Physijs.createMaterial(
      new THREE.MeshLambertMaterial({ color: 0xff6666 }), .8, .2)

    build: ->
      mesh = new Physijs.BoxMesh(new THREE.CubeGeometry(
          @width(),
          @height(),
          @length()),
        Body.material, 500)
      mesh.position.copy @position
      mesh

    addToScene: (scene) ->
      scene.add @mesh

  randomPointOnFace = (face) ->
    randA = Math.random()
    randB = Math.random()
    if randA + randB > 1
      randA = 1 - randA
      randB = 1 - randB
    randC = 1 - randA - randB
    vector = new THREE.Vector3()
    vector.x = (randA * face.a.x)+(randB * face.b.x)+(randC * face.c.x)
    vector.y = (randA * face.a.y)+(randB * face.b.y)+(randC * face.c.y)
    vector.z = (randA * face.a.z)+(randB * face.b.z)+(randC * face.c.z)
    [vector, face.normal]

  randomPointOnMesh = (mesh) ->
    index = Math.floor(Math.random() * mesh.geometry.faces.length)
    face = mesh.geometry.faces[index].clone()
    face.a = mesh.geometry.vertices[face.a]
    face.b = mesh.geometry.vertices[face.b]
    face.c = mesh.geometry.vertices[face.c]
    randomPointOnFace(face)


  # points = [
  #   [ new THREE.Vector3(5, 0, -5), new THREE.Vector3(0, 0, -1) ],
  #   [ new THREE.Vector3(-5, 0, -5), new THREE.Vector3(0, 0, -1) ],
  #   [ new THREE.Vector3(5, 0, 5), new THREE.Vector3(0, 0, 1) ],
  #   [ new THREE.Vector3(-5, 0, 5), new THREE.Vector3(0, 0, 1) ],
  # ]
  points = [
    [ new THREE.Vector3(5, 0, 0), new THREE.Vector3(1, 0, 0) ],
    [ new THREE.Vector3(-5, 0, 0), new THREE.Vector3(-1, 0, 0) ],
  ]
  genes = [0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5]
  class Car
    lineMaterial: new THREE.LineBasicMaterial({color: 0xffffff})
    constructor: (options) ->
      @genes = options.genes
      @position = options.position
      @body = new Body(@genes, @position)
      @wheels = []
      @lines = []

      for n in [1..2]
        # [position, normal] = randomPointOnMesh(@body.mesh)
        [position, normal] = points[n-1]
        @lines.push @createLine(position, normal)
        position = position.clone().add(@position)
        @wheels.push new Wheel(@genes, n, @body.mesh, position, normal)

    createLine: (position, normal) ->
      geometry = new THREE.Geometry()
      end = position.clone().add(normal.clone().multiplyScalar(5))
      geometry.vertices.push( position )
      geometry.vertices.push(end)
      new THREE.Line( geometry, @lineMaterial )

    addToScene: (scene) ->
      @body.addToScene(scene)
      for wheel in @wheels
        wheel.addToScene scene
        wheel.setupConstraints(scene)
      for line in @lines
        @body.mesh.add line

    start: ->
      for wheel in @wheels
        wheel.forward()

    stop: ->
      for wheel in @wheels
        wheel.stop()


  grid = new Grid(step: 5)
  grid.addToScene(scene)

  # car =  new Car(genes: Gene.random(7), position: new THREE.Vector3(0, 20, 0))
  # car =  new Car(genes: genes, position: new THREE.Vector3(0, 20, 0))
  # car.addToScene scene
  # car.start()
  # car.stop()

  # wheel = new Wheel([0.5,0.5, 0.5,0.5], 0, scene, new THREE.Vector3(0,10,0), new THREE.Vector3(0,0,1))

  material = Physijs.createMaterial(
    new THREE.MeshLambertMaterial({ map: THREE.ImageUtils.loadTexture( 'images/checker.gif' ) }),
      .8, .5)

  wheel_geometry = new THREE.CylinderGeometry(5, 5, 2, 16 )
  mesh = new Physijs.CylinderMesh(
    wheel_geometry,
    material,
    16)
  mesh.position.set(0, 10, 0)
  scene.add(mesh)
  constraint = new Physijs.DOFConstraint(mesh, mesh.position)
  scene.addConstraint(constraint)
  constraint.configureAngularMotor(1, 1, 0, -5, 2000)
  constraint.enableAngularMotor(1)

  requestAnimationFrame(render)

render = ->
  controls.update()
  requestAnimationFrame( render )
  scene.simulate( undefined, 2 )
  console.log mesh.rotation.toArray()
  renderer.render( scene, camera)

window.onload = initScene
