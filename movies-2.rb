require 'csv'

def sum(list)
  #finds the sum of a list (pretty self explanatory)
  total = 0
  list.each { |a| total+=a }
  return total
end

def average(list)
  #finds the average value of a list
  return sum(list).fdiv(list.length).round(2)
end

def standard_deviation(list,mean)
  #finds the standard value of a list (I used this to pick values)
  squares = 0
  list.each do |item|
    squares += (item-mean)**2
  end
  s = Math.sqrt(squares.fdiv((list.length)-1))
  return s.round(2)
end

class MovieData
  @@user_data = Hash.new #stores data about users and what they rate movies
  @@movie_data = Hash.new #stores data about movies and what they've been rated (as well as their popularity ranking)

  @@average_rating = 0 #average rating from 1-5
  @@std_rating=0 #standard deviation of that rating

  @@ratings_average=0 #average number of ratings
  @@ratings_average_std=0 #standard_deviation of above

  @@training_set = nil
  @@test_set = nil

  def initialize(folder,set="u")

    #I figured it might as well start loading the data
    load_data(folder,set)
  end

  def load_data(folder,set)
    if set=="u"
      @@training_set = folder+"/u.data"
    else
      @@training_set = folder+"/"+set+".base"
      @@test_set = folder+"/"+set+".test"
    end

    CSV.foreach(@@training_set) do |row|   #parses the CSV by row
      row_strings = row.first.split("\t") #parses the row by the tabs
      row_data = []
      row_strings.each do |item| #stores each item in the row into an array
        row_data += [Integer(item)]
      end
      user_id, movie_id, rating, timestamp = row_data #stores the data in respectable variables

      unless @@user_data.has_key? user_id #If that user ID hasn't been recorded before, it will make a blank hash as the value for the user ley
        @@user_data[user_id] = {}
      end
      @@user_data[user_id][movie_id] = rating #stores the rating they gave for that movie

      unless @@movie_data.has_key? movie_id #creates a hash where data about the movie can be stored
        @@movie_data[movie_id] = Hash.new {[]}
      end
      @@movie_data[movie_id][:ratings]+=[rating] #adds the rating to the list
      @@movie_data[movie_id][:users]+=[user_id]
    end
    self.stats() #calculates statistics on the movie
  end

  def rating(u,m)
    if @@user_data[u].has_key? m
      return @@user_data[u][m]
    end
    return 0
  end

  def predict(u,m)
    #Will predict what user u would rate a movie
    ratings_total = 0
    divisor = 0.1
    @@user_data.each do |user,reviews| #for each user in the training set
      if reviews.has_key? m # if that user has rated the movie
        p = similarity(u,user) #gets the similarity of that user to the user in question
        ratings_total+= (p*reviews[m]) #weights the ranking accordingly
        divisor += p
      end
    end
    return (ratings_total/divisor) #gets the average of the weighted rankings
  end

  def movies(u)
    return @@user_data[u]
  end

  def viewers(m)
    return  @@movie_data[m][:users]
  end

  def run_test(k=nil)
    if k.nil?
      k=20000
    end
    if @@test_set.nil?
      directory = @@training_set
    else
      directory = @@test_set
    end
    list_of_tuples = []
    initial_k=k
    CSV.foreach(directory) do |row|   #parses the CSV by row
      if k==0 #breaks after some point
        break
      end
      row_strings = row.first.split("\t") #parses the row by the tabs
      row_data = []
      row_strings.each do |item| #stores each item in the row into an array
        row_data += [Integer(item)]
      end
      user_id, movie_id, rating, timestamp = row_data #stores the data in respectable variables
      prediction = predict(user_id,movie_id)
      t = [user_id, movie_id, rating, prediction]
      list_of_tuples << t
      k-=1


    end
    return  MovieTest.new(list_of_tuples)
  end

  def stats
    movie_ratings = [] #average rating for each movie
    ratings_numbers = [] #number of reviews each movie gets
    @@movie_data.each do |movie,reviews|
      average_rating = average(reviews[:ratings]) #calculates the average rating for that movie
      @@movie_data[movie][:average] = average_rating #stores that average in the movie data
      movie_ratings << average_rating #adds it to the list of averages
      ratings_numbers << reviews[:ratings].length #adds number of ratings to list of number of ratings
    end

    @@average_rating = average(movie_ratings) #stores the average movie rating (for calculating std)
    @@ratings_average = average(ratings_numbers) #stores the average number of ratings
    @@std_rating = standard_deviation(movie_ratings,@@average_rating) #stores the std for both
    @@ratings_average_std = standard_deviation(ratings_numbers, @@ratings_average)
  end

  def popularity(movie_id)
    unless @@movie_data.has_key? movie_id
      return 0 #If the movie isn't in the database, it gets a rating of 0!
    end

    movie = @@movie_data[movie_id] #gets the data from the hash table about movies
    #otherwise it calculates the popularity of that movie
    #it does this by doing the log base 1.5 of the number of ratings multiplied by the average rating of the movie
    #the base 1.5 is pretty arbitrary, but I wanted this formula so that the number of ratings had some effect, but
    #in the end the movie wouldn't be popular unless it got good reviews

    # +1 so the log of 1 review isn't 0, and rounded for simplicity
    popularity = ((Math.log(movie[:ratings].length,1.2)+1)*movie[:average]).round(2)
    return popularity #returns that popularity
  end

  def popularity_list
    return (@@movie_data.sort_by{|k,v| popularity(k)}.reverse!).map {|k,v| k} #sorts the list by popularity in decreasing order
  end

  def similarity (user1, user2)
    users= [@@user_data[user1], @@user_data[user2]] #puts both users in an array to test the similarity of both
    ranks = [] #stores both the rankings so that they can be averaged
    2.times do |current_user|
      rank = 0
      other_user = (current_user + 1)%2
      users[current_user].each do |key,value|

        #if both users have a movie in common, then the algorithm adds 2 minus the difference in rankings
        #This is so that if they have a common opinion, they are more similar, but if they disagree they are not very similar
        if users[other_user].has_key? key
          rank += 2 - (value-users[other_user][key]).abs

        else #if they don't have a movie in common that means they are slightly less similar
          rank -= 0.12
        end
      end
      ranks << rank
    end

    return average(ranks) #average of 2 ranks (in case one person had lots of similar movies but other person had more)
  end

  def most_similar(id)
    closest = nil
    similarity = nil
    @@user_data.each do |user_id,data| #searches through everyone else's reviews
      unless id==user_id #check that you're not comparing yourself to yourself
        #Also note that a person will always be most similar to themself (if this line wasn't there)
        d = similarity(id,user_id)
        if similarity==nil or d>similarity #if nobody else is more similar it will store that person as more similar
          closest = user_id
          similarity = d
        end
      end
    end
    return closest #return person most similar to the user
  end
end

class MovieTest
  def initialize(ratings)
    @ratings = ratings
  end

  def mean
    differences = @ratings.map {|user_id, movie_id, rating, prediction| (rating-prediction).abs}
    return average(differences)
  end

  def std
    differences = @ratings.map {|user_id, movie_id, rating, prediction| (rating-prediction).abs}
    return standard_deviation(differences,mean)
  end

  def rms
    n=0
    sum=0
    @ratings.each do |user_id, movie_id, rating, prediction|
      sum += (rating-prediction)**2
      n+=1
    end
    return Math.sqrt(sum/@ratings.length)
  end

end

b = MovieData.new('ml-100k','u1') #loads the items from u1.base and u1.test
puts b.predict(1,1) #prediction of what user 1 rated toy story
puts b.rating(1,1) #what they actually rated toy story
print b.viewers(1) #the list of users that rated toy story
print "\n\n"

c = b.run_test(200) #test for the first 100 items in u1.test
puts "mean error"
puts c.mean #mean error of prediction
puts  "std of error"
puts c.std #standard deviation of the error
puts "mean squares of error"
puts c.rms #root mean squares of the error
print "\n"

#all the tests from movies-1
puts "Most popular movies:"
print b.popularity_list[0..9]
print "\n"

puts "Least popular movies (last 10 items):"
print b.popularity_list[-10..-1]
print "\n"

puts "User most similar to user 1:"
puts b.most_similar 1