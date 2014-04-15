Mongo Selectors are a new way, inspired by JQuery and CSS selectors, to perform complex queries in MongoDB with a relatively
simple syntax compared to writing JSON query objects by hand and handling indirect results and sub-document population by hand.

## Selector Samples

Let assume that we have a simple data model to support story voting on a web site. This is kept very simple to help you focus on the
selector syntax instead of trying to learn the domain model.

    users:
        _id : ObjectId
        username: String
        name: String
        rating: Number
    stories:
        _id: ObjectId
        author : DBRef('users')
        vote_count: Number
        voters : [DBRef('users')]
    comments:
        author: DBRef('users')
        story: DBRef('story')
        vote_count: Number
        voters: [DBRef('users')]

This basic model has a number of relationships that could make querying a little bit complex (cumbersome) with for example the JS MongoDB driver
or Mongoose. Let's explore a few selectors you could write from simple to complex.

### Retrieve all voters for a story

    stories#{{storyId}} > voters | *

This selector starts with the stories collection and select a specific entry by storyId. The storyId is a parameter that will be replaced at execution time. With this
 story in context, we go down to all voters, to get a list of user Ids. From these Ids, we pipe the result to the * operator to retrieve all attributes, not just the ID.
 The result is a list of user objects (not just their ids), ready to be manipulated by your application.

### Retrieve some negative comments fields

This example is a little more complex, but yet, is relatively easy to create using MongoDB Selectors.

    users[rating>=3] > comments!author{story[vote_count>0]}[vote_count<0] | author.name,text,vote_count

Let's start with the first element. We start with the users collection and select only users with a rating above or equals to 3. With this user subset in context,
we apply the next selector which is more complex. We first try to select comments from the user list we have in context. Because there are two fields referring to users
(author and voters), we must specify the one we want to use using the !author field of the stories collection to navigate the relationship. With only stories from users with
high rating in context, we then apply to kind of filters. The first one, within the round brackets is will the current collection based on conditions in a related
one. In this case, we want to filter comments of stories that are vote positive. To achieve this, we use the story relationship and apply an attribute filter to
only stories with vote_count > 0. With this restricted comment list, we retrieve only the ones with negative vote_count. We than transform the result to return the author name,
the text of the comment and the vote_count. By default, without the |, the query would have returned comment ids only.

### Reverses relationships

With selectors, we can also navigate relationship in reverse to create interesting queries.

    comments < author[rating>=3]|*

This will retrieve all authors that have rating above 3. We could have retrieve comments by using round brackets like that :

    comments{author[rating>=3] | *

With this selector, we keep the focus on the comments.

### Complex relationship navigation

We can go both ways in a single query.

    comments[vote_count>0, $interval(ts, -4W)] < author[rating>=3] > stories[vote_count>0] | **

The result will be stories, that have been authored by users with rating above 3 that have also written positive comments in the past 4 weeks. The ** symbol indicates
that we want not only all properties of the stories, but we want to populate its relationships also (author and all voters).

## Complex example

    users{stories!author: vote_count>0}[rating>$expectedRating] > stories{comments!story: $avg(vote_count) > $expectedRating}[vote_count > 0] | $sort:-vote_count | $limit:10 | **

Will return the top 10 stories, sorted by vote_count DESC which have comments of average vote_count above our expected rating parameter (3) from authors
of rating above our expected rating. The !author and !story qualifiers may not be specified if they can be implied by the provided schema. The engine will always favor
single relationship over many if multiple fields refering to the same entity are found. So in our case above, we could avoid indicating both qualifiers as they can
be safely infer by the engine.

