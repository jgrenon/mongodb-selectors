Q = require 'q'
_ = require 'lodash'
relations = require "./relations"
selectors = require "./selectors"

class QueryEngine
  constructor: (@parser) ->

  execute: (queryToParse) ->
    queries = @translate queryToParse
    @internalExecute queries, null

  internalExecute: (queries, startingResults) ->
    # From Jim Greenleaf's blog : Promise Chains with Node.js (https://coderwall.com/p/ijy61g)
    # Empty promise to start the chain
    promise_chain = Q(startingResults)

    _.forEach queries, (query) =>
      promise_link = (results) =>
        deferred = Q.defer()
        @applyResults(query, results).then( (theQuery) =>
          theQuery.exec (err, documents) =>
            return deferred.reject err if err

            if theQuery.smartscanContainSelector
              @reduce deferred, documents, theQuery.smartscanContainSelector.queries
            else
              deferred.resolve documents
        , (err) -> deferred.reject err
        ).catch (err) -> deferred.reject(err)

        deferred.promise

      # add the link onto the chain
      promise_chain = promise_chain.then(promise_link)

    return promise_chain

  translate: (queryToParse) ->
    parsedQuery = @parser.parse(queryToParse)
    _.flatten(selectors.createSelectors(parsedQuery))

  reduce: (deferred, documentsToReduce, queries) ->
    promises = []

    _.forEach documentsToReduce, (documentToCheck) =>
      reduceDeferred = Q.defer()
      promises.push reduceDeferred.promise

      @internalExecute(queries, [documentToCheck]).then( (documents) ->
        if (_.isEmpty(documents))
          reduceDeferred.resolve(null)
        else
          reduceDeferred.resolve(documentToCheck)
      , (err) -> reduceDeferred.reject(err)
      ).catch (err) -> reduceDeferred.reject(err)

    Q.all(promises).then( (results) ->
      reduceDocuments = _.filter results, (document) -> !_.isNull(document)
      deferred.resolve(reduceDocuments)
    , (err) -> deferred.reject(err)
    ).catch (err) -> deferred.reject(err)

  applyResults: (mongoQuery, results) ->
    return Q(mongoQuery) if _.isUndefined(mongoQuery.smartscan)
    return Q(mongoQuery) if _.isNull(results)

    if _.isEmpty(results)
      # NOTE (SG) : If no results, the pipe chain is broken. We ensure with this where clause to have no results from the query
      mongoQuery.where("_id").equals(mongoose.Types.ObjectId())
      return Q(mongoQuery)

    deferred = Q.defer()
    relations.selectStrategy(mongoQuery) deferred, mongoQuery, results
    return deferred.promise

module.exports = QueryEngine
