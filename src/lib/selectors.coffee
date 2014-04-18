mongoose = require 'mongoose'
_ = require 'lodash'

createSelectors = (parsedQuery, direction) ->
  if parsedQuery.type == "Selector"
    return [createSelectors(parsedQuery.left, direction), createSelectors(parsedQuery.right, { navigator: parsedQuery.navigator, fromSelector: parsedQuery.left})]
  else if  parsedQuery.type == "SimpleSelector"
    return [createQueryFromSimpleSelector(parsedQuery, direction)]
  else
    throw new Error "Unknown selector type #{parsedQuery.type}"

createQueryFromSimpleSelector = (parsedQuery, direction) ->
  mongoQuery = createQuery parsedQuery
  adjustQueryForExtendsPlugin parsedQuery, mongoQuery
  addDefaultSelectAttribute parsedQuery, mongoQuery

  addQualifier parsedQuery, mongoQuery
  addFilter parsedQuery, mongoQuery
  addDirection parsedQuery, mongoQuery, direction

  addContainSelector parsedQuery, mongoQuery

  return mongoQuery

createQuery = (parsedQuery) ->
  model = findMongooseModel parsedQuery
  return model.find()

findMongooseModel = (parsedQuery) -> mongoose.model(parsedQuery.element)

adjustQueryForExtendsPlugin = (parsedQuery, mongoQuery) ->
  # Special pass for extends plugin, to ensure valid type results by discriminator
  if !_.isUndefined(mongoQuery.model.schema.options.discriminatorKey)
    # Only add discriminator check to subclass only
    if !_.isUndefined(mongoQuery.model.schema.paths[mongoQuery.model.schema.options.discriminatorKey])
      mongoQuery.where(mongoQuery.model.schema.options.discriminatorKey).equals(adjustModelNameForExtendsPlugin(parsedQuery.element))

adjustModelNameForExtendsPlugin = (modelName) -> return modelName

addDefaultSelectAttribute = (parsedQuery, mongoQuery) ->
  if parsedQuery.filter && _.contains(parsedQuery.filter.attributes, '*')
    # NOOP - By default, no attribute selection in mongoose query will results with every attributes
  else if  parsedQuery.filter && _.contains(parsedQuery.filter.attributes, '**')
    # NOOP - By default, no attribute selection in mongoose query will results with every attributes
  else
    mongoQuery.select('_id')
    if !_.isUndefined(mongoQuery.model.schema.paths.id)
      mongoQuery.select('id')

    if !_.isUndefined(mongoQuery.model.schema.paths.path)
      mongoQuery.select('path')

    if !_.isUndefined(mongoQuery.model.schema.paths['node.ref'])
      mongoQuery.select('node.ref')

addQualifier = (parsedQuery, mongoQuery) ->
  if  parsedQuery.qualifier
    if parsedQuery.qualifier.type == "AttributeSelector"
      addQualifierAttributeSelector parsedQuery, mongoQuery
    else if parsedQuery.qualifier.type == "IDSelector"
      addQualifierIDSelector parsedQuery, mongoQuery
    else
      throw new Error("Unknown qualifier "+parsedQuery.qualifier.type)

addQualifierAttributeSelector = (parsedQuery, mongoQuery) ->
  _.forEach parsedQuery.qualifier.attributes, (attributeOperator) ->
    operatorName = null
    operatorValue = attributeOperator.value

    switch attributeOperator.operator
      when "=" then operatorName = "equals"
      when "!=" then operatorName = "ne"
      when ">" then operatorName = "gt"
      when "<" then operatorName = "lt"
      when ">=" then operatorName = "gte"
      when "<=" then operatorName = "lte"
      when "@" then operatorName = "in"
      when "!@" then operatorName = "nin"
      else
        operatorName = "exists"
        operatorValue = true

    if  _.isUndefined(operatorName)
      throw new Error("The '" + attributeOperator.operator + "' operator is not implemented")

    mongoQuery.where(attributeOperator.attribute)[operatorName](operatorValue)

addQualifierIDSelector = (parsedQuery, mongoQuery) -> mongoQuery.where("id").equals(parsedQuery.qualifier.id)

addFilter = (parsedQuery, mongoQuery) ->
  if parsedQuery.filter
    if parsedQuery.filter.type == "AttributeFilter"
      addFilterAttributeFilter parsedQuery, mongoQuery
    else
      throw new Error("Unknown filter type '" + parsedQuery.filter.type + "'")

addFilterAttributeFilter = (parsedQuery, mongoQuery) ->
  if _.contains(parsedQuery.filter.attributes, '*')
    # NOOP - By default, no attribute selection in mongoose query will results with every attributes
  else if _.contains(parsedQuery.filter.attributes, '**')
    mongoQuery.model.schema.eachPath (pathname, schemaType) ->
      if pathname != "_id" && schemaType.instance == 'ObjectID'
        mongoQuery.populate(pathname)
  else
    _.forEach parsedQuery.filter.attributes, (attr) -> mongoQuery.select(attr)

addDirection = (parsedQuery, mongoQuery, direction) ->
  if !_.isUndefined(direction)
    singleResult = (direction.fromSelector.qualifier) ? direction.fromSelector.qualifier.type == "IDSelector" : false

    if direction.navigator == "DOWN" || direction.navigator == "UP_FIRST" || direction.navigator == "UP_LAST"
      mongoQuery.smartscan =
        direction: direction.navigator
        from: direction.fromSelector.element
        to: parsedQuery.element
        singleResult: singleResult
    else
      throw new Error("Unknown navigator '" + direction.navigator + "'")

addContainSelector = (parsedQuery, mongoQuery) ->
  if parsedQuery.containSelector
    containQueries = createSelectors parsedQuery.containSelector,
      navigator: 'DOWN'
      fromSelector:
        qualifier:
          type: "IDSelector"
        element: adjustModelNameForExtendsPlugin(parsedQuery.element)
    mongoQuery.smartscanContainSelector =
      queries: containQueries

module.exports = createSelectors: createSelectors
