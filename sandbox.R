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

# You might have noticed that the set of atomic vectors does not include a number of important
# data structures like matrices, arrays, factors, or date-times. These types are built on top of
# atomic vectors by adding attributes.


a <- 1:3
attr(a,"x") <- "abcdef"
attr(a,"x")

attr(a,"y") <- 4:6
str(attributes(a))

a <- structure(
  1:3,
  x = "abcdef",
  y = 4:6
)
str(attributes(a))

# Attributes should generally be thought of as ephemeral. For example, most attributes are lost
# by most operations
 
# names, a character vector giving each element a name.
# dim, short for dimensions, an integer vector, used to turn vectors into matrices or arrays.

# Naming vectors (methods)
# 1
x <- c(a=1,b=2,c=3)
# 2
x <- 1:3
names(x) <- c("a","b","c")
# 3
x <- setNames(1:3,c("a","b","c"))

# remove names methods
# 1
unname(x)
# 2
names(x) <- NULL

a <- matrix(1:6,nrow = 2,ncol = 3)
a
b <- array(1:12,c(2,3,2))
b
c <- 1:6
dim(c) <- c(3,2)
c
str(attributes(a))
str(attributes(b))
str(attributes(c))


structure(1:5,.comment = "my attribute")

# In this section, we’ll discuss four important S3 vectors used in base R:
#   Categorical data, where values come from a fixed set of levels recorded in factor vectors.
#   Dates (with day resolution), which are recorded in Date vectors.
#   Date-times (with second or sub-second resolution), which are stored in POSIXct vectors.
#   Durations, which are stored in difftime vectors.

# Factors
x <- factor(c("a","b","b","a")) 
x
typeof(x)
attributes(x)

sex_char <- c("m","m","")
sex_factor <- factor(sex_char,levels=c("m","f"))
table(sex_factor)
table(sex_char)


grade <- ordered(c("b","b","a","c"), levels = c("c","b","a"))
grade

# While factors look like (and often behave like) character vectors, they are built on top of
# integers.


# Date vectors are built on top of double vectors. They have class “Date” and no other
# attributes:

today <- Sys.Date()
typeof(today)
attributes(today)


date <- as.Date("1970-02-01")
unclass(date)


# Base R10 provides two ways of storing date-time information, POSIXct, and POSIXlt. These
# are admittedly odd names: “POSIX” is short for Portable Operating System Interface, which
# is a family of cross-platform standards. “ct” standards for calendar time (the time_t type in C), 
# and “lt” for local time (the struct tm type in C). Here we’ll focus on POSIXct, because
# it’s the simplest, is built on top of an atomic vector, and is most appropriate for use in data
# frames. POSIXct vectors are built on top of double vectors, where the value represents the
# number of seconds since 1970-01-01.

now_ct <- as.POSIXct("2021-10-05 22:00",tz = "UTC")
now_ct
typeof(now_ct)
attributes(now_ct)

structure(now_ct,tzone = "America/New_York")
structure(now_ct,tzone = "Australia/Lord_Howe")


# Difftimes are built on top of doubles, and have a units attribute that
# determines how the integer should be interpreted:

one_week_1 <- as.difftime(1,units = "weeks")
one_week_1
typeof(one_week_1)
attributes(one_week_1)

one_week_2 <- as.difftime(1,units = "days")
attributes(one_week_2)


f1 <- factor(letters)
levels(f1) <- rev(levels(f1))
f1

f2 <- rev(factor(letters))
f3 <- factor(letters,levels = rev(letters))
f2
f3


l1 <- list(
  1:3,
  "a",
  c(TRUE,FALSE,TRUE),
  c(2.3,5.9)
)

typeof(l1)
str(l1)

lobstr::obj_size(mtcars)
l2 <- list(mtcars,mtcars)
lobstr::obj_size(l2)


l3 <- list(list(list(1)))
str(l3)

# c() will combine several lists into one. If given a combination of atomic vectors and lists,
# c() will coerce the vectors to lists before combining them.

l4 <- list(list(1,2),c(3,4))
l5 <- c(list(1,2),c(3,4))
str(l4)
str(l5)


list(1:3)
x = as.list(1:3)
x
as.vector(x)
unlist(x)


l <- list(1:3,"a",TRUE,1.0)
dim(l) <- c(2,2)
l
l[[1,1]]


c(date,now_ct)
list(date,now_ct)


# The two most important S3 vectors built on top of lists are data frames and tibbles.

df1 <- data.frame(x=1:3,y=letters[1:3])
typeof(df1)
attributes(df1)


library(tibble)

df2 <- tibble(x=1:3,y=letters[1:3])
typeof(df2)
attributes(df2)


str(df1)
df3 <- data.frame(
  x = 1:3,
  y = letters[1:3],
  stringsAsFactors = TRUE
)

str(df3)


# Creating a tibble is similar to creating a data frame. The difference between the two is that
# tibbles never coerce their input (this is one feature that makes them lazy):

# Additionally, while data frames automatically transform non-syntactic names (unless check.names = FALSE), 
# tibbles do not (although they do print non-syntactic names surrounded by `).

names(data.frame(`1` = 1))
names(tibble(`1` = 1))

# 
# While every element of a data frame (or tibble) must have the same length, both
# data.frame() and tibble() will recycle shorter inputs. However, while data frames
# automatically recycle columns that are an integer multiple of the longest column, tibbles will
# only recycle vectors of length one.





































































