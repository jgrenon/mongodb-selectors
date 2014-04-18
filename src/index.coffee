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

# Load the plugin with the generated parser
MongoSelectorPlugin = require './lib/plugin'

# Install the plugin in Mongoose (global plugin)
mongoose.plugin MongoSelectorPlugin


