mongoose = require 'mongoose'
require '../../build'
Q = require 'q'

describe 'Mongoose MongoSelector plugin', ->
  schema = null

  # Initialize our data model
  schema = new mongoose.Schema
    username: type: String
    email: type: String
    age: type: Number
  mongoose.model('user', schema);

  schema = new mongoose.Schema
    id: type: String
    title: type: String
    author: type: String
    rating: type: Number
  mongoose.model('story', schema);

  it 'should add the "select" method to all schema instances', () ->
    Model = mongoose.model('story')
    instance = new Model id: "1", title: "Story #1", author: "testuser",rating: 5

    expect(instance).toBeDefined()
    expect(instance.title).toBe("Story #1")
    expect(instance.author).toBe("testuser")
    expect(instance.select).toBeDefined()

  it 'should produce a promise for the selector result', () ->
    Model = mongoose.model('user')
    instance = new Model username: "testuser", email: "test@email.com", age: 35

    resultP = instance.select "user[age<=70.1]"
    expect(Q.isPromise(resultP)).toBeTruthy()

#    resultP.done (result) -> expect(result).toBeDefined()
#    resultP.fail (err) -> throw err
#    resultP.finally done
