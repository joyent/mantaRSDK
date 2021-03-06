\name{mantaFind.url}
\alias{mantaFind.url}
\title{Recursive find tool for retrieving matching objects/subdirs from Manta hierarchy.
Output is URL format listing with full pathnames.}
\usage{
mantaFind.url(mantapath, grepfor, entries, items = "o", level = 0,
  sortby = "none", starttime, endtime, decreasing = FALSE,
  ignore.case = FALSE, perl = FALSE, verbose = FALSE, info = TRUE)
}
\arguments{
  \item{mantapath}{character, optional. Current
  subdirectory set by \code{mantaSetwd} is used, otherwise
  specify full Manta path to subdirectory. Supports
  \code{~~} expansion to your Manta username, e.g.
  \code{"~~/public"} and UTF-8 encoded characters.}

  \item{grepfor}{character optional. Regular expression for
  \code{grep} name search. Ignored for reprocessed trees.
  Uses R regexps, N.B. use \code{"[.]txt"}, not
  \code{"*.txt"} to match filename extensions.}

  \item{entries}{optional. Saved mantaFind R data. For
  reprocessing/reformatting retrieved R tree information
  saved with \code{mantaFind(l='R')->tree}.}

  \item{items}{character optional. \code{'a'} for all,
  \code{'d'} for directory, \code{'o'} for object.}

  \item{level}{integer optional. Maximum number of
  subdirectory child levels to visit, in other words, the
  depth of the hierarchical directory search. If
  \code{level <= 0}, search depth is unrestricted. Level
  parameter is ignored on reprocessed search trees.}

  \item{sortby}{character, optional. Specify \code{'none',
  'name', 'time',} or \code{'size'.} Sorting selection is
  independent of time-bounded find.}

  \item{starttime}{POSIXlt time, optional. Start time for
  time-bounded find. When used without \code{endtime},
  \code{endtime} is set to current UTC time.}

  \item{endtime}{POSIXlt time, optional. End time for
  time-bounded find. When used without \code{starttime},
  \code{starttime} is set to start of Manta service}

  \item{decreasing}{logical, optional. Argument passed to R
  \code{order} for sorting.}

  \item{ignore.case}{logical, optional. Argument passed to
  R \code{grep} for searching.}

  \item{perl}{logical, optional. Argument passed to R
  \code{grep} for searching.}

  \item{verbose}{logical, optional. Verbose RCurl HTTP data
  output on Unix.}

  \item{info}{logical, optional. Console status messages
  about child path progress.}
}
\description{
Public HTTPS access is to objects in ~~/public subdirectory
only.  ~~/stor objects are not accessible. Search for
object or directory names with regular expressions (using R
grep). Sort listings by filename, time, or size.
}
\seealso{
\code{\link{mantaLs.url}}

Other mantaFind: \code{\link{mantaFind.du}};
\code{\link{mantaFind.l}}; \code{\link{mantaFind.n}};
\code{\link{mantaFind.sizepath}};
\code{\link{mantaFind.sizes}}; \code{\link{mantaFind}}
}

