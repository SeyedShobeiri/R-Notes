library(lobstr)

x <- c(1,2,3)
# It’s creating an object, a vector of values, c(1, 2, 3).
# And it’s binding that object to a name, x.
# In other words, the object, or value, doesn’t have a name; it’s actually the name
# that has a value.

# <- creates a binding from the name on the left-hand side to the object on the right-hand side.
# name is a reference to a value
y <- x

obj_addr(x)
obj_addr(y)

# A syntactic name must consist of letters1, digits, . and _ but can’t begin with _ or a digit.
?Reserved
# to use nonsyntactic names surround it by backticks
a <- 1:10
b <- a
c <- b
d <- 1:10

obj_addr(a)
obj_addr(b)
obj_addr(c)
obj_addr(d)

obj_addr(mean)
obj_addr(base::mean)
obj_addr(get("mean"))
obj_addr(evalq(mean))
obj_addr(match.fun("mean"))

#By default, base R data import functions, like read.csv(), will automatically convert non-syntactic names to syntactic ones
# make.names() creates syntactically valid names out of character vectors
# in read.csv() parameters check.name ensures that variable names are syntactically valid
# always use [[]] when getting or setting a simple element

y[[3]] = 4
obj_addr(x)
obj_addr(y)
# above behaviour is called copy-on-modify, R objects are unchangeable, or immutable


# tracemem() : let you know when an object gets copied

cat(tracemem(x),"\n")
y <- x
y[[3]] <- 4L

y[[3]] <- 5L
untracemem(y)


# Like vectors, lists use copy-on-modify behaviour
l1 <- list(1,2,3)
l2 <- l1
l2[[3]] <- 4
ref(l1,l2)

# Data frames are lists of vectors, so copy-on-modify has important consequences when you modify a data frame.

# R uses references is with character vectors3
x = c("a","a","abc","d")
ref(x,character = TRUE)

######## Object size
obj_size(letters)
obj_size(ggplot2::diamonds)
# Note : elements of a list are references to values
x = runif(1e6)
obj_size(x)

y = list(x,x,x)
obj_size(y)

obj_size(list(NULL,NULL,NULL))


# References also make it challenging to think about the size of individual objects. obj_size(x) + obj_size(y) will only equal obj_size(x, y) if there are no shared values.
obj_size(x,y)
obj_size(x) + obj_size(y)


# due to ALTREP every sequence no matter how large is the same size
obj_size(1:3)
obj_size(1:1e9)

# object.size() doesn't account for shared spaces
funs <- list(mean,sd,var)
obj_size(funs)

a <- runif(1e6)
obj_size(a)

b <- list(a,a)
obj_size(b)
obj_size(a,b)

b[[1]][[1]] <- 10
obj_size(b)
obj_size(a,b)

b[[2]][[1]] <- 10
obj_size(b)
obj_size(a,b)















