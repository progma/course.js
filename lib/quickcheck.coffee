

##
## Helpers
##
rand = Math.random

# Random sign
sign = ->
  if rand() > 0.5 then 1 else -1

# Sum of elements of array
sum = (arr) ->
  s = 0
  s += a for a in arr
  s

canShrink = (generator) ->
  'shrink' of generator

##
## Arbitrary object generators
##

# Generator of random boolean
arbBool = ->
  (if rand() > 0.5 then true else false)

# Generator of random byte
arbByte = ->
  Math.floor rand() * 256

# Generator of random double
arbDouble = ->
  sign() * rand() * Number.MAX_VALUE

# Generator of random double depending on given size
arbSizedDouble = (size) ->
  sign() * rand() * size

# Generator of random integer
arbInt = ->
  sign() * Math.floor(rand() * Number.MAX_VALUE)

# Generator of random integer depending on given size
arbSizedInt = (size) ->
  sign() * Math.floor(rand() * size)

# Generator of random character (0-255)
arbChar = ->
  String.fromCharCode arbByte()

# Generator of random array of given length with each element generated by
# another generator (given as second parameter)
arbArrayOf = (length,generator) -> makeShrinking
  create: (size) ->
    generator(size) for i in [0...length]

  shrink: (arr) ->
    return [] if not canShrink generator
    res = []

    for i in [0...arr.length]
      for g in generator.shrink arr[i]
        arr1 = arr.slice 0
        arr1.splice i, 1, g
        res.push arr1
    res

arbArrayPrim = (generator,minimum) -> makeShrinking
  create: (size) ->
    dimension = Math.round(rand() * size) + minimum
    (arbArrayOf dimension, generator)(size)

  shrink: (arr) ->
    return [] if arr.length < minimum

    res = for i in [0...arr.length]
      arr1 = arr.slice 0
      arr1.splice i, 1
      arr1

    res.concat arbArrayOf(arr.length, generator).shrink arr

# Generator of random array of random size
# :: Gen a -> Gen [a]
arbArray = (generator) ->
  arbArrayPrim generator, 0

# Generator of random array of random non-empty size
# :: Gen a -> Gen [a]
arbArray1 = (generator) ->
  arbArrayPrim generator, 1

# Generator of random string
arbString = (size) ->
  arbArray(arbChar)(size).join ""

# Generator of random double between #{l} and #{u}
choosePrim = (l, u) ->
  rand() * (u-l) + l

# Generator of random integer between #{l} and #{u}
choosePrimInt = (l, u) ->
  Math.round (choosePrim l, u)

# Create generator of random real number between #{l} and #{u}
arbChoose = (l, u) -> ->
  choosePrim l, u

##
## Helpers for creating custom generators
##
makeShrinking = (obj) ->
  f = obj.create  # TODO different name to create?
  f.shrink = obj.shrink
  f

# Creates generator selecting uniformly from given generators (given in Array)
# :: [Gen a] -> Gen a
oneOf = (arr) -> (size) ->
  l = arr.length
  i = choosePrimInt 0, l-1
  arr[i](size)

# Creates generator selecting uniformly from given array
# :: [a] -> Gen a
elements = (arr) -> ->
  l = arr.length
  i = choosePrimInt  0, l-1
  arr[i]

# Creates generator selecting with a weighted random distribution from given
# generators.
#
# Gets an array of pairs (pair is two element array) with first elements a
# frequency and seconds a generators.
#
# :: [(Int, Gen a)] -> Gen a
frequency = (arr) -> (size) ->
  s = sum (el[0] for el in arr)
  bound = choosePrimInt 0, s

  ss = 0
  for el in arr
    ss += el[0]
    if ss >= bound
      return el[1] size

##
## Testing factory
##

computeSize = (args,n,d) ->
  maxSize = args.maxSize
  maxSuccess = args.maxSuccess
  roundNtoD = Math.floor(n / maxSize) * maxSize

  if roundNtoD + maxSize <= maxSuccess ||
       n >= maxSuccess                 ||
       maxSuccess % maxSize == 0
    n % maxSize + d/10
  else
    (n % maxSize)*maxSize / (maxSuccess % maxSize) + d/10

generateShrinks = (generators, values) ->
  res = []
  for i of generators when canShrink generators[i]
    for gen in generators[i].shrink values[i]
      values1 = values.slice(0)
      values1.splice i, 1, gen
      res.push values1
  res

minCounterexample = (agrFun) -> (property, generators, shrinkNum, values) ->
  shrinks = generateShrinks generators, values
  min = values

  while shrinkNum-- != 0 && shrinks.length != 0
    values = shrinks.shift()

    if false == property.apply null, values
      shrinks = agrFun shrinks, generateShrinks generators, values
      min = values

  min

# Brute force search for minimal counterexample
globalMin =
  minCounterexample (oldShrinks, newShrinks) -> oldShrinks.concat newShrinks

# Search for locally minimal counterexample
localMin =
  minCounterexample (oldShrinks, newShrinks) -> newShrinks


stdArgs =
  maxSuccess  :   100
  maxDiscards :  1000 # maximum number of discarded before giving up
  maxSize     :   100 # size to use for the biggest test cases
  chatty      : false # whether to print anything
  shrinkNum   :    -1 # try shrinking of counterexample in order to find
                      # a smaller one (-1 allows infinite shrink attempts)
  user : undefined    # environment accessible for tested property via @user

# Run tests of given property.
# Returns either true or array of failing values.
runWith = (args, property) ->
  generators = Array::slice.call(arguments, 2)

  n = 0  # number of successfully ran tests
  d = 0  # number of discarded tests
  while n < args.maxSuccess && d < args.maxDiscards
    size   = computeSize args, n, d
    values = generators.map (f) -> f size
    logObj =
      failReason: ""
      size: size
      user: args.user  # export user environment

    switch property.apply logObj, values
      # Test succeeded
      when true  then n++

      # Test failed
      when false
        console.log "*** Failed!  #{logObj.failReason}" if args.chatty

        # Fail report
        return {
          values: localMin property, generators, args.shrinkNum, values
          logObj: logObj
        }

      # Test discarded
      else
        d++

  if d == args.maxDiscards
    console.log "*** Gave up! Passed only #{n} tests." if args.chatty
    return false
  else
    console.log "+++ OK, passed #{args.maxSuccess} tests." if args.chatty
    return true

# Run tests of given property.
# Uses default test arguments.
# Returns either true or failing values.
run = (property) ->
  runWith stdArgs, arguments...

##
## Exports
##
(exports ? this).quickCheck =
  # Arbitrary object generators
  arbBool       : arbBool
  arbByte       : arbByte
  arbDouble     : arbDouble
  arbSizedDouble: arbSizedDouble
  arbInt        : arbInt
  arbSizedInt   : arbSizedInt
  arbChar       : arbChar
  arbArray      : arbArray
  arbArray1     : arbArray1
  arbArrayOf    : arbArrayOf
  arbString     : arbString
  arbChoose     : arbChoose

  # Helpers for creating custom generators
  makeShrinking : makeShrinking
  oneOf         : oneOf
  elements      : elements
  frequency     : frequency

  # Testing factory
  run           : run
  runWith       : runWith
  stdArgs       : stdArgs