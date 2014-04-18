###
    MongoDB Selectors, a CSS selector inspired query engine for MongoDB
    Copyright (C) 2014 Joel Grenon & Sébastien Guimont

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
###

mongoose = require 'mongoose'
PEG = require 'pegjs'
Handlebars = require 'handlebars'
fs = require 'fs'
path = require 'path'
_ = require 'lodash'

module.exports = (schema, options) ->

  # Regenerate our parser with this new schema added
  parser = generateParser()

  # Add selector method to all schema instances
  schema.methods.select = (s, options = {}) ->
    # Always append the current object has the root of the selector
    s = @constructor.modelName + "#" + @id + " > " +s
    query = parser.parse s

    #TODO: Execute the query

  # Add a static version to execute selectors without a starting context
  schema.statics.select = (s, options = {}) ->
    query = parser.parse s

    #TODO: Execute the query

generateParser = () ->

  # Generate the PEG file
  pegTmplSrc = fs.readFileSync path.resolve(__dirname, "../selector-parser.hbs")

  # Produce our model names list
  Handlebars.registerHelper 'modelNames', () ->
    out = ""

    modelNames = _.keys(mongoose.modelSchemas)

    for name in modelNames
      if out.length > 0
        out += " / "
      out += "'#{name}'"
    return out

  pegTmpl = Handlebars.compile(pegTmplSrc + "")
  pegFile = pegTmpl()

  # Generate the parser based on the generate peg syntax
  return PEG.buildParser(pegFile + "", optimize:'speed')
