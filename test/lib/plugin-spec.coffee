mongoose = require 'mongoose'
require '../../build'
Q = require 'q'

describe 'Mongoose MongoSelector plugin', ->
  schema = null

  beforeEach ->
    schema = new mongoose.Schema
      id: type: String
      field1: type: String
      field2: type: Number
    mongoose.model('test1', schema);

    schema = new mongoose.Schema
      id: type: String
      field1: type: String
      test1: type: String
    mongoose.model('test2', schema);

  it 'should add the select method to all schema instance', (done) ->
    Model = mongoose.model('test2')
    instance = new Model id: "122", field1: "test", test1: "123"

    expect(instance).toBeDefined()
    expect(instance.field1).toBe("test")
    expect(instance.test1).toBe("123")
    expect(instance.select).toBeDefined()

    resultP = instance.select "test1[attr=false]"
    expect(Q.isPromise(resultP)).toBeTruthy()
    resultP.done (result) -> expect(result).toBeDefined()
    resultP.fail (err) -> throw err
    resultP.finally done
