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


x <- data.frame(matrix(runif(5*1e4),ncol=5))
medians <- vapply(x,median,numeric(1))

for (i in seq_along(medians)) {
  x[[i]] <- x[[i]] - medians[[i]]
}

cat(tracemem(x),"\n")

for (i in 1:5){
  x[[i]] <- x[[i]] - medians[[i]]
}

untracemem(x)

# In fact, each iteration copies the data frame not once, not twice, but three times! Two copies are made by [[.data.frame, and a further copy7 is made because
# [[.data.frame is a regular function that increments the reference count of x. We can reduce the number of copies by using a list instead of a data frame.
# Modifying a list uses internal C code, so the references are not incremented and only a single copy is made

y = as.list(x)
cat(tracemem(y),"\n")
for (i in 1:5){
  y[[i]] <- y[[i]] - medians[[i]]
}


# environments are always modified in place.
e1 = rlang::env(a=1,b=2,c=3)
e2 <- e1
e1$c <- 4
e2$c

# environments can contain themselves
e1$self <- e1
ref(e1)

tracemem(e1)


median_subtractor = function(data){
  medians <- vapply(data,median,numeric(1))
  for (i in seq_along(medians)){
    data[[i]] = data[[i]] - medians[[i]]
  }
  return(data)
}

data_df = list(matrix(runif(5*1e6),ncol=5))
bench::bench_time(median_subtractor(data_df))

gcinfo(TRUE)

gc()
lobstr::mem_used()


# quote non-syntactic names with backticks: `
df <- data.frame(runif(3),runif(3))
names(df) <- c(1,2)
df$`3` <- df$`1` + df$`2`

df

# Vectors come in two flavours: atomic vectors and lists2. They differ in terms of their elements’ types: for atomic vectors, all elements must have the same type; 
# for lists, elements can have different types. most important S3
# vectors: factors, date and times, data frames, and tibbles. And while 2D structures like
# matrices and data frames are not necessarily what come to mind when you think of vectors,
# you’ll also learn why R considers them to be vectors.

# There are four primary types of atomic vectors: logical, integer, double, and character (which contains strings).
# Integers are written similarly to doubles but must be followed by L
# Strings are surrounded by ” (”hi”) or ’ (’bye’). Special characters are escaped with \


int_var <- c(1L,2L,3L)
typeof(int_var)
length(int_var)


# R represents missing, or unknown values, with special sentinel value: NA (short for not applicable).
# Missing values tend to be infectious: most computations involving a missing
# value will return another missing value.

x <- c(NA,5,NA,10)
x == NA
is.na(x)

# combining character and integer yields a character:

str(c("a",1))

# Coercion often happens automatically. Most mathematical functions (+, log, abs, etc.) will
# coerce to numeric. This coercion is particularly useful for logical vectors because TRUE
# becomes 1 and FALSE becomes 0.

# For atomic vectors, type is a property of the entire vector: all elements must be the same type.
# When you attempt to combine different types they will be coerced in a fixed order: character
# → double → integer → logical.

x <- c(FALSE,TRUE,FALSE)
as.numeric(x)

as.integer(c("1","1.5","a"))

raw(2)
complex(1,3,4)

c(1,FALSE)
c("a",1)
c(TRUE,1L)
c(FALSE,NA_character_)
