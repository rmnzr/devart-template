class mk.helpers.JointFollower
  constructor : (@view, @joint, @zOffset) ->
    @view.z = 0
    @zOffset = @zOffset || Math.random() + 50
  update : ->
    @view.position.x = @joint.x
    @view.position.y = @joint.y
    @view.z = @joint.z + @zOffset

class mk.helpers.PartFillFollower
  constructor : (@view, @part, @weights, @zOffset) ->
    @view.z = 0
    @zOffset = @zOffset || Math.random() * 100 + 200
    @joints = @part.joints
    if @joints.length > 3
      @joints = @joints.slice(0, 3)
  update : ->
    x = 0
    y = 0
    for j,i in @joints
      x += j.x * @weights[i]
      y += j.y * @weights[i]
    @view.position.x = x
    @view.position.y = y
    @view.z = @part.z + @zOffset


class mk.helpers.PartEdgeFollower
  constructor : (@view, @j1, @j2, @pct, @zOffset) ->
    @zOffset = @zOffset || 0
    # console.log @zOffset
  update : ->
    x = @j1.x * @pct + @j2.x * (1-@pct)
    y = @j1.y * @pct + @j2.y * (1-@pct)
    @view.position.x = x
    @view.position.y = y
    @view.z = @j1.z * @pct + @j2.z * (1-@pct) + @zOffset


class mk.helpers.SimpleJointItem
  constructor : (@symbol, @joint, @zOffset) ->
    @view = @symbol.place()
    @view.z = 0
    @follower = new mk.helpers.JointFollower @view, @joint, @zOffset
  update: ->
    @follower.update()


class mk.helpers.SimplePartItem
  constructor: (@symbol, @part, @seed) ->
    @view = @symbol.place()
    @view.z = 0
    weights = mk.helpers.getRandomWeights @part.joints, @seed
    @follower = new mk.helpers.PartFillFollower @view, @part, weights, rng(@seed) * 100 + 200
  update: ->
    @follower.update()


class mk.helpers.JointVelocityTracker
  constructor : (jnts) ->
    @velocities = []
    @prev = []
    @jnts = []
    for j in jnts
      @add j
  add : (jnt) ->
    @velocities.push 0
    p = new paper.Point(0, 0)
    @prev.push p
    @jnts.push jnt
  remove : (jnt) ->
    i = 0
    for i in [0...@jnts.length]
      if jnt is @jnts[i] then break
    @velocities.splice i,1
    @prev.splice i,1
    @jnts.splice i,1
  update: ->
    for j,i in @jnts
      p = @prev[i]
      dx = j.x - p.x
      dy = j.y - p.y
      @velocities[i] = (dx*dx + dy*dy)
      p.x = j.x
      p.y = j.y
    return
  get: (i) ->
    return @velocities[i]


class mk.helpers.Rotate3d
  constructor: (@item) ->
    @view = new paper.Group()
    @view.transformContent = false
    @item.pivot = new paper.Point @item.bounds.width*0.5, 0
    @view.addChild @item
    @h1 = true
  update : ->
    if @h1
      @view.matrix.a -= 0.03
      @view.matrix.c -= 0.015
      if @view.matrix.a < 0.03
        @h1 = false
    else 
      @view.matrix.a -= 0.03
      @view.matrix.c += 0.015
      if @view.matrix.a < -0.9
        @view.matrix.a = 1
        @view.matrix.c = 0
        @h1 = true

mk.helpers.getRandomWeights = (joints, seed) ->
  weights = []
  sum = 0
  for j,i in joints
    if i < 3
      w = rng(seed)
      weights.push w
      sum += w
  weights[i] /= sum for w,i in weights
  return weights

class mk.helpers.FloatFollower
  constructor : (@view) ->
    rngk = 'floatfollow'
    @speed = rng(rngk)*0.01 + 0.001
    @ang   = rng(rngk)*Math.PI
    @dist  = 0#rng(rngk)*200 + 15
    @dest  = {x:0, y:0}
  update : (dt) ->
    @ang += dt * @speed
    p =
      x : Math.cos(@ang)*@dist
      y : Math.sin(@ang)*@dist
    p.x += @dest.x
    p.y += @dest.y
    @view.position.x += (p.x-@view.position.x) * @speed * dt
    @view.position.y += (p.y-@view.position.y) * @speed * dt