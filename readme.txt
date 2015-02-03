Movie prediction algorithm for COSI 166b (Software Engineering)
An example usage is in the client code

Code climate: https://codeclimate.com/github/misingnoglic/movies-2
Github repo: www.github.com/misingnoglic/movies-2

My algorithm for predicting a movie rating is to go through all the users in the training set, and see what they rated that movie
I then multiplied that rating by the similarity to the user, to create a scaled average (users that are more similar to the
user in question have their ratings weighted higher)

The algorithm isn't perfect, but it seems to be around 1 off. It's more accurate for more popular movies.

THe downside to the algorithm is that it takes an extremely long time to run. One example run took 247 seconds

Here's the stats on u1
mean error
1.48
std of error
16.99
mean squares of error
17.054901668755043